`timescale 1ns/1ps
`ifndef P7_BO_REDUCED
//`define P7_BO_REDUCED 1
`endif
`ifndef PIX_8
//`define PIX_8
`endif
			
module sao_top #(
	parameter diff_clip_bit = 4,
	parameter n_category = 4,
	parameter n_category_bo = 8,
	parameter num_pix_CTU_log2 = 5,
	parameter blk_22_X_len = 6,
	parameter blk_22_Y_len = 6,
	parameter n_pix = 4,
	parameter org_window_width = 2,
	parameter org_window_height = n_pix/org_window_width,
	parameter bit_depth = 8,
	parameter pic_width_len = 13,
	parameter pic_height_len = 13,
	parameter cnt_st_len = 10,
	parameter cnt_dc_len = 6,
	parameter isChroma  = 0,
	parameter cut_x_len = 9,
	parameter cut_y_len = 9,
	parameter num_accu_len = num_pix_CTU_log2*2-1,
	
parameter n_eo_type = 4,
parameter sao_type_len = 3,
parameter offset_len = 4
	
)(		
	input logic 									clk,clk_slow,arst_n,rst_n,
	input logic 	[pic_width_len-1:0]				pic_width,		
	input logic 	[pic_height_len-1:0]			pic_height,



//	input logic	[blk_22_X_len-1:0]					X_,
//	input logic	[blk_22_X_len-1:0]					Y_,
	input logic 									en_i,en_o,
	//en_o_2,

	input logic 	[cut_x_len-1:0]					ctu_x,
	input logic 	[cut_y_len-1:0]					ctu_y,
	input logic   [2:0]								ctb_size_log2,
	input logic 	[bit_depth-1:0] 				n_org_m[0:n_pix-1],	
	input logic 	[bit_depth-1:0] 				rec_in[0:org_window_height+1][0:org_window_width+1],
	input logic	[2:0]								ctu_size,
	input logic   [8:0]								lamda[0:2],

	output	logic 			[sao_type_len-1:0]										sao_type[0:1],
	output	logic 	signed	[offset_len-1:0]										offset[0:n_category-1],
	output	logic 			[1:0]    												sao_mode[0:1],					//0： OFF    1:NEW   2:MERGE
	output	logic 			[$clog2(32)-1:0]   										typeAuxInfo[0:2],
	
	output	logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU[0:n_eo_type-1][0:n_category-1],
	output	logic 	[num_accu_len:0]											num_blk_CTU[0:n_eo_type-1][0:n_category-1],

	output	logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU_bo[0:n_category_bo-1],
	output	logic 	[num_accu_len:0]											num_blk_CTU_bo[0:n_category_bo-1],
	
	output	logic   								wait_forPre,
	output	logic	[1:0]							cIdx,
	output   logic			[9:0]														cnt_st,
	output   logic			[5:0]														cnt_dc,
	output   logic			[1:0]														cIdx_dc
	
	);

	parameter 	EO_0 		= 0;
	parameter 	EO_45 		= 1;
	parameter 	EO_90 		= 2;
	parameter	EO_135 		= 3;
	

	logic 									en_o_2;
	logic	[blk_22_X_len-1:0]				X;

	logic	[blk_22_Y_len-1:0]				Y;
	logic									not_end;
	logic									not_end_pre_stage;

	logic	[1:0]							cIdx_r1;
	logic 	[bit_depth-1:0] 				n_rec_m[0:n_pix-1];
	logic signed [diff_clip_bit:0]			n_diff[0:n_pix-1];
	
	logic 									isAboveAvail;
	logic 									isLeftAvail;
	logic 									isLeftAboveAvail;
	logic									isLeftMergeAvail;
	logic									isUpperMergeAvail;
	logic									isLeftMergeAvail_dc;
	logic									isUpperMergeAvail_dc;
	logic  	[n_pix-1:0]						b_use[0:n_eo_type-1];
	logic  	[n_pix-1:0]						b_use_bo;
	
	logic 									isWorking_deci;
	logic 									isWorking_stat;
	logic 									isWorking_stat_r1;

	logic   								wait_forPre_r1;
	//logic 									clk_slow;
	logic									end_of_luma_st;
	logic									end_of_chroma_st;
	logic									is_bo_pre;
	logic									isToRefresh,able_to_pass,end_s;
	
	logic	[4:0]							cand_bo_r1;
	logic	[4:0]							cand_bo[0:2];
	logic	[4:0]							cand_bo_[0:2];
	logic	[4:0]							cand_bo_dc[0:2];
	
	
	logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU_DCI[0:n_eo_type-1][0:n_category-1];
	logic 	[num_accu_len:0]											num_blk_CTU_DCI[0:n_category-1][0:n_category-1];
	logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU_bo_DCI[0:n_category_bo-1];
	logic 	[num_accu_len:0]											num_blk_CTU_bo_DCI[0:n_category_bo-1];
	logic																	not_end_r1;
	logic																	not_end_pre_stage_r1;
	logic 	signed 	[diff_clip_bit:0]										n_diff_r1[0:n_pix-1];

	
	logic [4:0] 							X_len;
	logic [4:0] 							Y_len;	
	logic 	[cut_x_len-1:0]					ctu_x_dc;
	logic 	[cut_y_len-1:0]					ctu_y_dc;
	
	assign n_rec_m[0]= rec_in[1][1];
	assign n_rec_m[1]= rec_in[1][2];
	assign n_rec_m[2]= rec_in[2][1];
	assign n_rec_m[3]= rec_in[2][2];
`ifdef PIX_8	
	assign n_rec_m[4]= rec_in[1][3];
	assign n_rec_m[5]= rec_in[1][4];
	assign n_rec_m[6]= rec_in[2][3];
	assign n_rec_m[7]= rec_in[2][4];
	assign b_use_bo =8'b11111111;
`else 
	assign b_use_bo =4'b1111;
`endif
	
	
generate
	for(genvar i=0; i<n_pix; i=i+1) begin:xi	
		sao_stat_one_pixel_diff #(.diff_clip_bit(4)) sao_stat_one_pixel_diff(
					.rec_m(n_rec_m[i]), 
					.org_m(n_org_m[i]), 
					.diff(n_diff[i]) 
				);
	end
endgenerate	

	
sao_stat_boundary  sao_stat_boundary(
	.pic_width(pic_width),	
	.pic_height(pic_height),
	.ctu_x(ctu_x),
	.ctu_y(ctu_y),
	.ctu_size(ctu_size),
	.X,
	.Y,
	.isAboveAvail,
	.isLeftAvail,
	.isLeftAboveAvail,
	.cIdx,
	.X_len,
	.Y_len,
	.*
);

sao_FSM	sao_FSM(
	.clk,
	.arst_n,
	.rst_n,
	.en_i(en_i),
	.en_o(en_o),
	.ctb_size_log2(ctb_size_log2-cIdx[1]),
	.ctu_x(ctu_x),
	.ctu_y(ctu_y),
	.X_len,
	.Y_len,
	.isToRefresh,
	.X,
	.Y,
	.not_end,
	.not_end_pre_stage,
	.cIdx,
	.end_of_luma_st,
	.end_of_chroma_st,
	.wait_forPre,
	.isWorking_deci,
	.isWorking_stat,
	.is_bo_pre,
	.able_to_pass,
	.end_s,
	.cnt_st,
	.*
);
sao_stat_bo_reduce #(.n_pix(n_pix)) sao_stat_bo_reduce(
	.clk,
	.rst_n,
	.arst_n,
	.wait_forPre,
	.not_end_pre_stage,
	.cIdx,
	.n_rec_m,
	.cand_bo,
	.en_o(en_o),
	.is_bo_pre,
	.isWorking_stat,
	.*
);



sao_stat_type_bo #(.n_category(n_category_bo),.num_pix_CTU_log2(num_pix_CTU_log2),.num_accu_len(num_accu_len),.n_pix(n_pix) ) sao_stat_type_bo(
	.clk,
	.clk_slow,
	.arst_n,
	.rst_n,
	.en_i(en_i),
	.en_o(en_o),
	.n_rec_m,
	.n_diff(n_diff_r1),
	.not_end(not_end_r1),
	.b_use(b_use_bo),		//this pix is avail. or not.
	.sum_blk_CTU(sum_blk_CTU_bo),
	.num_blk_CTU(num_blk_CTU_bo),
	.wait_forPre(wait_forPre_r1),
	.isWorking_stat(isWorking_stat_r1),
	.cIdx(cIdx_r1),
	.cand_bo_(cand_bo),
	.isToRefresh,
	.*
);

sao_stat_pip_1to2 #(.n_pix(n_pix)) sao_stat_pip_1to2(
	.en_i,
	.en_o,
	.cIdx,
	.cIdx_r1,
	.not_end,
	.not_end_pre_stage,
	.not_end_r1,
	.not_end_pre_stage_r1,
	.isWorking_stat_r1,
	.wait_forPre_r1,
	.*
);
sao_stat_mask #(.n_pix(n_pix)) sao_stat_mask(
		.X,
		.Y,
		.isAboveAvail,
		.isLeftAvail,
		.isLeftAboveAvail,
		.b_use(b_use),
		.*
	);

	
generate
	for(genvar eo_type=0;eo_type<4;eo_type++) begin: type_loop
		sao_stat_type #(.EO_TYPE(eo_type),.num_pix_CTU_log2(num_pix_CTU_log2),.num_accu_len(num_accu_len),.n_pix(n_pix) ,.org_window_width(org_window_width)) sao_stat_type(
		.clk,
		.clk_slow,
		.arst_n,
		.rst_n,
		.en_i(en_i),
		.en_o(en_o),
		.rec_in(rec_in),
		.n_rec_m,
		.n_diff(n_diff_r1),
		.not_end(not_end_r1),
		.b_use(b_use[eo_type]),		//this pix is avail. or not.
		.sum_blk_CTU(sum_blk_CTU[eo_type]),
		.num_blk_CTU(num_blk_CTU[eo_type]),
		.isWorking_stat(isWorking_stat),
		.isWorking_stat_r1(isWorking_stat_r1),
		.wait_forPre(wait_forPre_r1),
		.isToRefresh,
		.*
	);
	end
endgenerate

/*
sao_clk_gen sao_clk_gen(
	.*
);
*/

sao_pip_1to2 #(.num_pix_CTU_log2(num_pix_CTU_log2),.num_accu_len(num_accu_len)) sao_pip_1to2(
	.clk_slow,
	.ctu_x(ctu_x),
	.ctu_y(ctu_y),
	.cIdx,
	.ctu_x_dc,
	.ctu_y_dc,
	.en(en_o),
	.en_2(en_o_2),
//	.en_2(1'b1),
	.end_of_luma_st,
	.end_of_chroma_st,
	.cand_bo,
	.cand_bo_dc,
	.num_blk_CTU(num_blk_CTU),
	.sum_blk_CTU(sum_blk_CTU),
	.num_blk_CTU_bo(num_blk_CTU_bo),
	.sum_blk_CTU_bo(sum_blk_CTU_bo),
	.num_blk_CTU_DCI(num_blk_CTU_DCI),
	.sum_blk_CTU_DCI(sum_blk_CTU_DCI),
	.num_blk_CTU_bo_DCI(num_blk_CTU_bo_DCI),
	.sum_blk_CTU_bo_DCI(sum_blk_CTU_bo_DCI),
	.able_to_pass,
	.isLeftMergeAvail,
	.isUpperMergeAvail,
	.isLeftMergeAvail_dc,
	.isUpperMergeAvail_dc,
	.*
);
/*
sao_deci_top #(.n_category_bo(n_category_bo), .num_pix_CTU_log2(num_pix_CTU_log2),.num_accu_len(num_accu_len)) sao_deci_top (
	.clk(clk_slow),
	.en_i,
	.en_o,
	.sao_type,
	.sao_mode,			
	.sao_typeAuxInfo(typeAuxInfo),
	.offset_o(offset),
	.lamda(lamda),
	.cand_bo(cand_bo_dc),
	.rst_n,
	.arst_n,
	
	.cur_ctu_x(ctu_x_dc),
	.cur_ctu_y(ctu_y_dc),
	.sum_blk_CTU_DCI,
	.num_blk_CTU_DCI,
	.sum_blk_CTU_bo_DCI,
	.num_blk_CTU_bo_DCI,
	
	.isLeftMergeAvail(isLeftMergeAvail_dc),
	.isUpperMergeAvail(isUpperMergeAvail_dc),
	.isWorking_deci,
	.end_s,
	.cnt_dc_r1(cnt_dc),
	.cIdx_r1(cIdx_dc),
	.*
);
*/
endmodule

