`timescale 1ns/1ps
module sao_deci_top #(
	parameter num_pix_CTU_log2 = 5,
	parameter diff_clip_bit = 4,
	parameter offset_len = 4,
	parameter sao_type_len = 3,
	parameter state_len = 6,
	parameter n_eo = 6,
	parameter n_category = 4,
	parameter n_offset = 4,
	parameter n_category_bo = 8,
	parameter n_eo_type = 4,
	parameter dist_len = 21,
	parameter num_accu_len = num_pix_CTU_log2*2-1,
	parameter num_CTU = num_accu_len,
	parameter eo_bo_type_len = 5,
	parameter lamda_len		 = 9,
	parameter n_total_type 	= 5,
	parameter ctu_x_len 	= 9,
	parameter ctu_y_len 	= 9
)
(
	input   																			clk,rst_n,arst_n,en_i,en_o,
	input   logic			[ctu_x_len-1:0]												cur_ctu_x,
	input   logic			[ctu_y_len-1:0]												cur_ctu_y,
	input	logic																		end_s,
	input	logic 	signed [num_accu_len+diff_clip_bit:0]							sum_blk_CTU_DCI[0:n_eo_type-1][0:n_category-1],
	input	logic 			[num_accu_len:0]										num_blk_CTU_DCI[0:n_category-1][0:n_category-1],
	input	logic 	signed [num_accu_len+diff_clip_bit:0]							sum_blk_CTU_bo_DCI[0:n_category_bo-1],
	input 	logic 			[num_accu_len:0]										num_blk_CTU_bo_DCI[0:n_category_bo-1],
	input	logic																		isLeftMergeAvail,
	input	logic																		isUpperMergeAvail,
	input   logic 			[lamda_len-1:0]												lamda[0:2],
	input	logic			[4:0]														cand_bo[0:2],

	output	logic 			[sao_type_len-1:0]											sao_type[0:1],
	output 	logic 			[1:0]    													sao_mode[0:1],					//0： OFF    1:NEW   2:MERGE
	output 	logic 			[eo_bo_type_len-1:0]   										sao_typeAuxInfo[0:2],
	output  logic	signed	[offset_len-1:0]											offset_o[0:n_offset-1],
	output   logic																		isWorking_deci,
	output   logic			[state_len-1:0]												cnt_dc_r1,
	output   logic			[1:0]														cIdx_r1
);	

	logic			[1:0]														cIdx;
	logic			[state_len-1:0]												cnt_dc;
	logic 			[offset_len-1:0] 											u_offset;
	logic 			[num_CTU:0]	 												num_blk_CTU;
	logic 	signed 	[num_CTU+diff_clip_bit:0] 									sum_blk_CTU;
	logic 	signed 	[dist_len-1:0] 												distortion;
	
	logic 	signed 	[offset_len-1:0]											offset_eo[0:1][0:n_eo_type-1][0:n_category-1];
	logic 	signed 	[offset_len-1:0]											offset_bo[0:1][0:n_category_bo-1];
	
	logic 	signed 	[dist_len-1+n_category:0] 									dist_one_type;
	logic 	signed 	[dist_len-1+n_category:0] 									dist_bo_type_best;
	logic			[2:0]												best_bo_category;

	logic 	signed [dist_len+n_category:0]    									cost_L[0:n_total_type-1];
	logic 	signed [dist_len+n_category+1:0]    								cost_C[0:n_total_type-1];
	logic																		isWorking_deci_r1;
	logic 	signed [dist_len+n_category:0] 										cost_one_type;
	
	logic			[4:0]														cand_bo_r1[0:2];
	logic 			[sao_type_len-1:0]											sao_type_toStore[0:1];
	logic 			[$clog2(32)-1:0]   											best_typeAuxInfo[0:2];
	logic			[2:0]														typeAuxInfo_3bit_ary[0:2];

	
	logic			[2:0]														L_merge_sao_type[0:1];
	logic			[1:0]														L_merge_sao_mode[0:1];
	logic			[$clog2(32)-1:0]											L_typeAuxInfo[0:2];
	logic			[2:0]														U_merge_sao_type[0:1];
	logic			[1:0]														U_merge_sao_mode[0:1];
	logic			[$clog2(32)-1:0]											U_typeAuxInfo[0:2];
	logic	signed	[offset_len-1:0]											merge_offset[0:n_offset-1];
	logic 																		isChroma;
	
	assign				isChroma = |cIdx;
	
	always_ff @(posedge clk or negedge arst_n)
		if(!arst_n)
			{isWorking_deci_r1,cIdx_r1,cand_bo_r1[0],cand_bo_r1[1],cand_bo_r1[2]} <= 0;
		else if(!rst_n)
			{isWorking_deci_r1,cIdx_r1,cand_bo_r1[0],cand_bo_r1[1],cand_bo_r1[2]} <= 0;
		else begin
			if(en_o)
			{isWorking_deci_r1,cIdx_r1,cand_bo_r1[0],cand_bo_r1[1],cand_bo_r1[2]} <= {isWorking_deci,cIdx,cand_bo[0],cand_bo[1],cand_bo[2]};
		end
		
 	
//assign sao_typeAuxInfo[0] =  best_typeAuxInfo[0]+cand_bo[0]-3;
//assign sao_typeAuxInfo[1] =  best_typeAuxInfo[1]+cand_bo[1]-3;
//assign sao_typeAuxInfo[2] =  best_typeAuxInfo[2]+cand_bo[2]-3;

assign sao_typeAuxInfo[0] =  best_typeAuxInfo[0];
assign sao_typeAuxInfo[1] =  best_typeAuxInfo[1];
assign sao_typeAuxInfo[2] =  best_typeAuxInfo[2];

sao_FSM_deci sao_FSM_deci(
	.clk,
	.end_s,
	.arst_n,
	.rst_n,
	.en_i,
	.en_o,
	.cnt_dc_fsm(cnt_dc),
	.isWorking_deci,
	.cIdx_fsm(cIdx)
);



	
sao_deci_dist_arrange #(.n_category_bo(n_category_bo),.num_pix_CTU_log2(num_pix_CTU_log2),.num_accu_len(num_accu_len)) sao_deci_dist_arrange(
	.sum_blk_CTU_DCI,
	.num_blk_CTU_DCI,
	.sum_blk_CTU_bo_DCI,
	.num_blk_CTU_bo_DCI,
	.cnt_dc,
	.isWorking_deci,
	.cand_bo(cand_bo[cIdx]),

	.L_merge_sao_type(L_merge_sao_type[isChroma]),
	.L_merge_sao_mode(L_merge_sao_mode[isChroma]),
	.L_typeAuxInfo(L_typeAuxInfo[cIdx]),
	.U_merge_sao_type(U_merge_sao_type[isChroma]),
	.U_merge_sao_mode(U_merge_sao_mode[isChroma]),
	.U_typeAuxInfo(U_typeAuxInfo[cIdx]),
	.num_blk_CTU,
	.sum_blk_CTU
);



sao_deci_merge #(.n_category_bo(n_category_bo)) sao_deci_merge(
	.clk,
	.arst_n,
	.rst_n,
	.en(en_o),
	.cur_merge_sao_type(sao_type),
	.cur_merge_sao_mode(sao_mode),
	.cur_typeAuxInfo(typeAuxInfo_3bit_ary),
	.typeAuxInfo_w(sao_typeAuxInfo),
	.cur_ctu_x,
	.cur_ctu_y,
	.cIdx(cIdx_r1),

	.L_merge_sao_type,
	.L_merge_sao_mode,
	.L_typeAuxInfo,
	.U_merge_sao_type,
	.U_merge_sao_mode,
	.U_typeAuxInfo,
	
	.isLeftMergeAvail,
	.isUpperMergeAvail,
	
	.merge_offset,
	.offset_eo,
	.offset_bo,
	.cnt_dc_r(cnt_dc),
	.cnt_dc_w(cnt_dc_r1),
	.offset_toStore(offset_o)
);

sao_deci_init_offset #(.n_category_bo(n_category_bo),.num_pix_CTU_log2(num_pix_CTU_log2),.num_accu_len(num_accu_len)) sao_deci_init_offset(
	.num_blk_CTU,
	.sum_blk_CTU,
	.cnt_dc,
	.cIdx,
	.merge_offset,
	.offset_eo,
	.offset_bo,
	.init_offset(u_offset),
	.clk,
	.en(en_o),
	.rst_n,
	.arst_n

);

sao_deci_dist #(.num_pix_CTU_log2(num_pix_CTU_log2),.num_accu_len(num_accu_len)) sao_deci_dist(
	.u_offset,
	.num_blk_CTU,
	.sum_blk_CTU,
	.distortion
);

sao_deci_dist_accu_shift sao_deci_dist_accu_shift(
	.clk,
	.arst_n,
	.rst_n,
	.distortion,
	.isLeftMergeAvail,
	.isUpperMergeAvail,
	.dist_one_type,	
	.dist_bo_type_best,	
	.best_bo_category,	//3bit
	.en(en_o),
	.cnt(cnt_dc),
	.cnt_r1(cnt_dc_r1)
);

sao_deci_cost sao_deci_cost(
	.cnt(cnt_dc_r1),
	.isWorking_deci(isWorking_deci_r1),
	.lamda(lamda),
	.best_sao_type(sao_type),
	.sao_mode,
	.best_typeAuxInfo,	//5bit
	.cIdx(cIdx_r1),
	.cand_bo(cand_bo_r1),
	.clk,
	.rst_n,
	.arst_n,
	.en_o,
	.dist_one_type,
	.best_bo_category,	//3bit
	.dist_bo_type_best,
	.isLeftMergeAvail,
	.isUpperMergeAvail,
	.L_typeAuxInfo,
	.U_typeAuxInfo,
	.L_merge_sao_type,
	.U_merge_sao_type,
	.typeAuxInfo_3bit_ary

);

 


endmodule