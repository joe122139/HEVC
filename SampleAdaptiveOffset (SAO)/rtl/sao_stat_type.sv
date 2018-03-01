`timescale 1ns/1ps
module sao_stat_type #(
parameter EO_TYPE = 0,
parameter bit_depth = 8, 
parameter diff_clip_bit = 4,
parameter n_pix = 4,
parameter org_window_width = 2,
parameter org_window_height = n_pix/org_window_width,
parameter n_category = 4,
parameter cnt_st_len = 10,
parameter num_pix_CTU_log2 = 5,
parameter num_accu_len = num_pix_CTU_log2*2-1

)(
	input	logic  									clk,
	input	logic  									clk_slow,
	input	logic  									arst_n,
	input	logic  									rst_n,
	input	logic    								en_i,
	input	logic    								en_o,
	input   logic 	[bit_depth-1:0] 				rec_in[0:org_window_height+1][0:org_window_width+1],
	input	logic 	[bit_depth-1:0] 				n_rec_m[0:n_pix-1],
	input 	logic signed 	[diff_clip_bit:0]		n_diff[n_pix],
	input 	logic									not_end,
	input	[n_pix-1:0]								b_use,			//this pix is avail. or not.
	input 	logic 									isWorking_stat,
	input 	logic 									isWorking_stat_r1,
	
	input   logic 									wait_forPre,
	input	logic									isToRefresh,
//	input	logic									is_to_pass_data,

	output	logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU[0:n_category-1],
	output 	logic 	[num_accu_len:0]		num_blk_CTU[0:n_category-1]
//	output	logic signed [num_pix_CTU_log2*2+diff_clip_bit:0]						sum_blk_CTU_DCI[0:n_category-1],
//	output 	logic 	[num_pix_CTU_log2*2:0]		num_blk_CTU_DCI[0:n_category-1]
);
	
logic 			[n_pix-1:0]							sel[0:n_category-1];
logic  			[2:0]								eo_cate [0:n_pix-1];
logic 	[bit_depth-1:0] 							n_rec_l[0:n_pix-1];
logic 	[bit_depth-1:0] 							n_rec_r[0:n_pix-1];
logic signed 	[diff_clip_bit+2:0]					s41;
logic signed 	[diff_clip_bit+2:0]					s31;
logic signed 	[diff_clip_bit+1:0]					s21;
logic signed 	[diff_clip_bit:0]					s11;
`ifdef PIX_8
logic signed 	[diff_clip_bit+3:0]					s51;
logic signed 	[diff_clip_bit+3:0]					s61;
logic signed 	[diff_clip_bit+3:0]					s71;
logic signed 	[diff_clip_bit+3:0]					s81;
`endif

logic 			[n_pix-1:0]							b_use_r1;	
logic  			[2:0]								eo_cate_r1 [0:n_pix-1];
logic 			[n_pix-1:0]							sel_r1[0:n_category-1];
logic 			[n_pix-1:0]							sel_r2[0:n_category-1];
logic 												wait_forPre_r1;
logic												not_end_r1;
//logic 	signed 	[diff_clip_bit:0]					n_diff_r1[0:n_pix-1];
//logic												not_end_r1;

logic 												isWorking_stat_r2;

always_ff @(posedge clk or negedge arst_n)
	if(!arst_n) begin
		//{n_diff_r1[0],n_diff_r1[1],n_diff_r1[2],n_diff_r1[3]} <=0;
		{eo_cate_r1[0],eo_cate_r1[1],eo_cate_r1[2],eo_cate_r1[3],b_use_r1,isWorking_stat_r2,not_end_r1,wait_forPre_r1} <=0;
		`ifdef PIX_8
		{eo_cate_r1[4],eo_cate_r1[5],eo_cate_r1[6],eo_cate_r1[7]} <= 0;
		`endif
		{sel_r1[0],sel_r1[1],sel_r1[2],sel_r1[3]} <=0;
		{sel_r2[0],sel_r2[1],sel_r2[2],sel_r2[3]} <=0;
		//not_end_r1 <= 0;
		
	end
	else if (!rst_n) begin
		//{n_diff_r1[0],n_diff_r1[1],n_diff_r1[2],n_diff_r1[3]} <=0;
		{eo_cate_r1[0],eo_cate_r1[1],eo_cate_r1[2],eo_cate_r1[3],b_use_r1,isWorking_stat_r2,not_end_r1,wait_forPre_r1} <=0;
		`ifdef PIX_8
		{eo_cate_r1[4],eo_cate_r1[5],eo_cate_r1[6],eo_cate_r1[7]} <= 0;
		`endif
		{sel_r1[0],sel_r1[1],sel_r1[2],sel_r1[3]} <=0;
		{sel_r2[0],sel_r2[1],sel_r2[2],sel_r2[3]} <=0;

	end
	else begin
		if(en_o)	begin
			//{n_diff_r1[0],n_diff_r1[1],n_diff_r1[2],n_diff_r1[3]} <= {n_diff[0],n_diff[1],n_diff[2],n_diff[3]};
			{eo_cate_r1[0],eo_cate_r1[1],eo_cate_r1[2],eo_cate_r1[3],b_use_r1} <={eo_cate[0],eo_cate[1],eo_cate[2],eo_cate[3],b_use};
			`ifdef PIX_8
			{eo_cate_r1[4],eo_cate_r1[5],eo_cate_r1[6],eo_cate_r1[7]} <= {eo_cate[4],eo_cate[5],eo_cate[6],eo_cate[7]} ;
			`endif
			{sel_r1[0],sel_r1[1],sel_r1[2],sel_r1[3]} <={sel[0],sel[1],sel[2],sel[3]};
			{sel_r2[0],sel_r2[1],sel_r2[2],sel_r2[3]} <={sel_r1[0],sel_r1[1],sel_r1[2],sel_r1[3]};
		//	not_end_r1 <= not_end;
			isWorking_stat_r2 <= isWorking_stat_r1;
			not_end_r1<= not_end;
			wait_forPre_r1<= wait_forPre;
		end
	
	end

always_comb begin
			if(isWorking_stat)	begin
				`ifdef PIX_8
					sel[0] = {(3'd1) == eo_cate[0],(3'd1) == eo_cate[1],(3'd1) == eo_cate[2],(3'd1) == eo_cate[3],(3'd1) == eo_cate[4],(3'd1) == eo_cate[5],(3'd1) == eo_cate[6],(3'd1) == eo_cate[7]} & {b_use[0],b_use[1],b_use[2],b_use[3],b_use[4],b_use[5],b_use[6],b_use[7]};
					sel[1] = {(3'd2) == eo_cate[0],(3'd2) == eo_cate[1],(3'd2) == eo_cate[2],(3'd2) == eo_cate[3],(3'd2) == eo_cate[4],(3'd2) == eo_cate[5],(3'd2) == eo_cate[6],(3'd2) == eo_cate[7]} & {b_use[0],b_use[1],b_use[2],b_use[3],b_use[4],b_use[5],b_use[6],b_use[7]};
					sel[2] = {(3'd3) == eo_cate[0],(3'd3) == eo_cate[1],(3'd3) == eo_cate[2],(3'd3) == eo_cate[3],(3'd3) == eo_cate[4],(3'd3) == eo_cate[5],(3'd3) == eo_cate[6],(3'd3) == eo_cate[7]} & {b_use[0],b_use[1],b_use[2],b_use[3],b_use[4],b_use[5],b_use[6],b_use[7]};
					sel[3] = {(3'd4) == eo_cate[0],(3'd4) == eo_cate[1],(3'd4) == eo_cate[2],(3'd4) == eo_cate[3],(3'd4) == eo_cate[4],(3'd4) == eo_cate[5],(3'd4) == eo_cate[6],(3'd4) == eo_cate[7]} & {b_use[0],b_use[1],b_use[2],b_use[3],b_use[4],b_use[5],b_use[6],b_use[7]};
				`else
					sel[0] = {(3'd1) == eo_cate[0],(3'd1) == eo_cate[1],(3'd1) == eo_cate[2],(3'd1) == eo_cate[3]} & {b_use[0],b_use[1],b_use[2],b_use[3]};
					sel[1] = {(3'd2) == eo_cate[0],(3'd2) == eo_cate[1],(3'd2) == eo_cate[2],(3'd2) == eo_cate[3]} & {b_use[0],b_use[1],b_use[2],b_use[3]};
					sel[2] = {(3'd3) == eo_cate[0],(3'd3) == eo_cate[1],(3'd3) == eo_cate[2],(3'd3) == eo_cate[3]} & {b_use[0],b_use[1],b_use[2],b_use[3]};
					sel[3] = {(3'd4) == eo_cate[0],(3'd4) == eo_cate[1],(3'd4) == eo_cate[2],(3'd4) == eo_cate[3]} & {b_use[0],b_use[1],b_use[2],b_use[3]};
				`endif

			end
			else	begin
				sel[0] = 0;
				sel[1] = 0;
				sel[2] = 0;
				sel[3] = 0;
			
			end
end



sao_stat_rec_matching #(.EO_TYPE(EO_TYPE), .n_pix(n_pix) ,.org_window_width(org_window_width)) sao_stat_rec_matching
	(.*);


sao_stat_n_pix #(.EO_TYPE(EO_TYPE), .n_pix(n_pix)) sao_stat_n_pix(
	.n_rec_l,
	.n_rec_r,
	.n_rec_m,
	.eo_cate
);

sao_stat_n_pix_add #(.n_pix(n_pix), .n_bo_type(3)) sao_stat_n_pix_add (
	.n_diff,
	.cate(eo_cate_r1),
	.s41(s41),
	.s31(s31),
	.s21(s21),
	.s11(s11),
	.isWorking_stat(isWorking_stat_r1),
	.b_use(b_use_r1),
	.en(en_o),
	.*
	);
	

generate
	for(genvar i=0;i<n_category;i++) begin:loopi

		sao_stat_accu #(.num_pix(n_pix), .num_pix_CTU_log2(num_pix_CTU_log2),.num_accu_len(num_accu_len)) sao_stat_accu(
		.clk_slow,
		.s41,
		.s31,
		.s21,
		.s11,
		.sel(sel_r2[i]),
		.sum_blk_CTU(sum_blk_CTU[i]),
		.num_blk_CTU(num_blk_CTU[i]),
//		.sum_blk_CTU_DCI(sum_blk_CTU_DCI[i]),
//		.num_blk_CTU_DCI(num_blk_CTU_DCI[i]),
		.clk,
		.not_end(not_end_r1),
		.wait_forPre(wait_forPre_r1),
		.isToRefresh,
//		.is_to_pass_data,
		.*
	);
	end
endgenerate
	
	
endmodule
