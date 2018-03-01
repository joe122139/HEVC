`timescale 1ns/1ps
module sao_pip_1to2 #(
	parameter ctu_x_len = 9,
	parameter ctu_y_len = 9,
	parameter diff_clip_bit = 4,
	parameter n_category = 4,
	parameter n_category_bo = 8,
	parameter num_pix_CTU_log2 = 5,
	parameter num_accu_len = num_pix_CTU_log2*2-1,
	parameter n_eo_type = 4
)(
	input	logic																		clk_slow,arst_n,rst_n,en,
	input	logic	[1:0]																cIdx,
	input	logic																		isLeftMergeAvail,
	input	logic																		isUpperMergeAvail,	
	input	logic																		end_of_luma_st,
	input	logic																		end_of_chroma_st,
	input   logic			[ctu_x_len-1:0]												ctu_x,
	input   logic			[ctu_y_len-1:0]												ctu_y,
	input	logic			[4:0]														cand_bo[0:2],
	input	logic																		able_to_pass,
	
	input	logic signed [num_accu_len+diff_clip_bit:0]							sum_blk_CTU[0:n_eo_type-1][0:n_category-1],
	input 	logic 	[num_accu_len:0]												num_blk_CTU[0:n_eo_type-1][0:n_category-1],
	input	logic signed [num_accu_len+diff_clip_bit:0]							sum_blk_CTU_bo[0:n_category_bo-1],
	input	logic 	[num_accu_len:0]												num_blk_CTU_bo[0:n_category_bo-1],   
	
	output	logic			[ctu_x_len-1:0]												ctu_x_dc,
	output	logic			[ctu_y_len-1:0]												ctu_y_dc,
	output	logic																		en_2,
	output	logic			[4:0]														cand_bo_dc[0:2],
	output	logic																		isLeftMergeAvail_dc,
	output	logic																		isUpperMergeAvail_dc,
	
	output 	logic 	[num_accu_len:0]												num_blk_CTU_DCI[0:n_eo_type-1][0:n_category-1],
	output 	logic signed [num_accu_len+diff_clip_bit:0]							sum_blk_CTU_DCI[0:n_eo_type-1][0:n_category-1],
	output	logic signed [num_accu_len+diff_clip_bit:0]							sum_blk_CTU_bo_DCI[0:n_category_bo-1],
	output	logic 	[num_accu_len:0]												num_blk_CTU_bo_DCI[0:n_category_bo-1]
);

  
logic 																		is_to_pass_data;

always_ff @(posedge clk_slow or negedge arst_n)
	if(!arst_n)	begin
		{ctu_x_dc,ctu_y_dc} <= 0;
		{isLeftMergeAvail_dc,isUpperMergeAvail_dc} <= 0;
		en_2 <= 0;
		{cand_bo_dc[0],cand_bo_dc[1],cand_bo_dc[2]}<=0;
		 is_to_pass_data <=0;
	end
	else if(!rst_n) begin
		{ctu_x_dc,ctu_y_dc} <= 0;
		{isLeftMergeAvail_dc,isUpperMergeAvail_dc} <= 0;
		en_2 <= 0;
		{cand_bo_dc[0],cand_bo_dc[1],cand_bo_dc[2]}<=0;
		 is_to_pass_data <=0;
	end
	else begin
		en_2 <= en;
		is_to_pass_data <= able_to_pass;
		if(en) begin
			if(end_of_luma_st) begin
				{isLeftMergeAvail_dc,isUpperMergeAvail_dc} <= {isLeftMergeAvail,isUpperMergeAvail};
				{ctu_x_dc,ctu_y_dc} <= {ctu_x,ctu_y};
			end
			if(end_of_luma_st) begin
				cand_bo_dc[0] <= cand_bo[0];
			end
			if(end_of_chroma_st && cIdx==1) begin
				cand_bo_dc[1] <= cand_bo[1];
			end
			if(end_of_chroma_st && cIdx==2) begin
				cand_bo_dc[2]<= cand_bo[2];
			end
		end
	end
	
generate 
for(genvar eo_type=0;eo_type<n_eo_type;eo_type++)	begin:lp_type
	for(genvar cate=0;cate<n_category;cate++)	begin:lp_cate
		always_ff @(posedge clk_slow or negedge arst_n) 
			if(!arst_n) begin
				{sum_blk_CTU_DCI[eo_type][cate],num_blk_CTU_DCI[eo_type][cate]} <= 0;
			end
			else if(!rst_n) begin
				{sum_blk_CTU_DCI[eo_type][cate],num_blk_CTU_DCI[eo_type][cate]} <= 0;
			end
			else begin
				if(is_to_pass_data)	begin
					sum_blk_CTU_DCI[eo_type][cate] <= sum_blk_CTU[eo_type][cate];
					num_blk_CTU_DCI[eo_type][cate] <= num_blk_CTU[eo_type][cate];
				end
			end
	end
end
endgenerate

generate 
	for(genvar bo_cate=0;bo_cate<n_category_bo;bo_cate++)	begin:lp_bo_cate
		always_ff @(posedge clk_slow or negedge arst_n) 
			if(!arst_n) begin
				{sum_blk_CTU_bo_DCI[bo_cate],num_blk_CTU_bo_DCI[bo_cate]} <= 0;
			end
			else if(!rst_n) begin
				{sum_blk_CTU_bo_DCI[bo_cate],num_blk_CTU_bo_DCI[bo_cate]} <= 0;
			end
			else begin
				if(is_to_pass_data)	begin
					sum_blk_CTU_bo_DCI[bo_cate] <= sum_blk_CTU_bo[bo_cate];
					num_blk_CTU_bo_DCI[bo_cate] <= num_blk_CTU_bo[bo_cate];
				end
			end
	end
endgenerate
endmodule