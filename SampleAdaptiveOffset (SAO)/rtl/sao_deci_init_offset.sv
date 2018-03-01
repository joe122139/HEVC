`timescale 1ns/1ps
module sao_deci_init_offset #(
	parameter num_pix_CTU_log2 = 5,
	parameter diff_clip_bit = 4,
	parameter num_accu_len = num_pix_CTU_log2*2-1,
	parameter num_CTU = num_accu_len,
	parameter offset_len = 4,
	parameter sum_CTU_len = num_CTU+diff_clip_bit,
	parameter n_category = 4,
	parameter n_category_bo = 32,
	parameter n_offset = 4,
	parameter state_len = 6,
	parameter n_eo_type = 4,
	parameter SHIFT = 24
	
)
(
	input	logic																clk,arst_n,rst_n,en,
	input 	logic 			[num_CTU:0] 										num_blk_CTU,
	input 	logic 	signed 	[sum_CTU_len:0] 									sum_blk_CTU,
	input   logic			[state_len-1:0]										cnt_dc,
	input   logic			[1:0]												cIdx,
	input   logic	signed	[offset_len-1:0]									merge_offset[0:n_offset-1],
	
	output 	logic 	signed 	[offset_len-1:0]									init_offset,
	output	logic 	signed 	[offset_len-1:0]									offset_eo[0:1][0:n_eo_type-1][0:n_category-1],
	output	logic 	signed 	[offset_len-1:0]									offset_bo[0:1][0:n_category_bo-1]
);

//assign init_offset = sum_blk_CTU / num_blk_CTU;
//	logic [num_CTU:0] num_sft_1;
//	logic [num_CTU+1:0] num_sft_2;
//	logic [num_CTU-1:0] half_num;
	logic [num_CTU+1:0] num_sft_1;
	logic [num_CTU+2:0] num_sft_2;
	logic [num_CTU:0] half_num;
	logic [sum_CTU_len-1:0] un_sum;
	logic [offset_len-2:0] un_offset;
	logic 	signed 	[offset_len-1:0]									init_offset_;
	
	assign num_sft_1 = num_blk_CTU<<<1;
	assign num_sft_2 = num_blk_CTU<<<2;
	assign half_num = (num_blk_CTU+1)>>1;
	assign un_sum = sum_blk_CTU[sum_CTU_len-1]? (~(sum_blk_CTU-1)) : sum_blk_CTU[sum_CTU_len-2:0];
	always_comb begin
		init_offset_ = 0;
		un_offset = 0;
		if (num_blk_CTU==0 || sum_blk_CTU == 0)
			un_offset = 0;
		else if( un_sum >= num_sft_1+num_blk_CTU + half_num) begin	// >= 3.5, (4,5,6,7)
			un_offset[2] = 1;
			if( un_sum  >= num_sft_2 + num_blk_CTU + half_num)	begin// 5.5~7.4
				un_offset[1] = 1;
				un_offset[0] = un_sum >= (num_sft_2 + num_sft_1 + half_num);
			end
			else begin		//3.5 ~ 5.4
				un_offset[1] = 0;
				un_offset[0] = un_sum >= (num_sft_2 + half_num);
			end
		end
		else begin	//(0,1,2,3)
			un_offset[2] = 0;
			if( un_sum  >= num_blk_CTU + half_num )	begin// 2, 3
				un_offset[1] = 1;
				un_offset[0] = un_sum >= (num_sft_1 + half_num);
			end
			else	begin	//0,1
				un_offset[1] = 0;
				un_offset[0] = un_sum >= half_num;
			end
		end
		
		if (sum_blk_CTU[sum_CTU_len-1])
			init_offset_ = ~un_offset + 1;
		else
			init_offset_ = {1'b0,un_offset[offset_len-2:0]};
		
		init_offset = init_offset_;
		
		if(cnt_dc<5'd16 && cnt_dc[1]==0 && sum_blk_CTU[sum_CTU_len-1])	//valley & offset <0
			init_offset = 0;
		if(cnt_dc<5'd16 && cnt_dc[1]==1 && !sum_blk_CTU[sum_CTU_len-1]) // peak & offset >0
			init_offset = 0;
		if(cnt_dc>47-SHIFT && cnt_dc<56-SHIFT)
			init_offset = merge_offset[cnt_dc%4];
	end
	
	generate
		for(genvar idx=0; idx<2; idx++)	begin:gen_idx
			for(genvar typeIdx=0; typeIdx <n_eo_type; typeIdx++) begin:gen_typeIdx
				for(genvar cate=0; cate <n_category; cate++) begin:gen_cate
					always_ff @(posedge clk or negedge arst_n)
						if(!arst_n)	begin
							offset_eo[idx][typeIdx][cate] <= 4'd0;
						end
						else if(!rst_n) begin
							offset_eo[idx][typeIdx][cate] <= 4'd0;
						end
						else begin
							if(en) begin
					/*			if(cIdx[1] && cnt_dc == 59)	begin
									offset_eo[0][typeIdx][cate] <= 0;
									offset_eo[1][typeIdx][cate] <= 0;
								end
								else */if(cate== cnt_dc%4 && typeIdx==cnt_dc/4 && idx == cIdx[1])
									offset_eo[idx][typeIdx][cate] <= init_offset;
							end
						end
				end
			end
			
			for(genvar bo_cate=0; bo_cate<n_category_bo;bo_cate++)	begin:gen_bo_cate
				always_ff @(posedge clk or negedge arst_n)
					if(!arst_n)	begin
						offset_bo[idx][bo_cate] <= 0;
					end
					else if(!rst_n) begin
						offset_bo[idx][bo_cate] <= 0;
					end
					else begin
						if(en) begin
						/*	if(cIdx[1] && cnt_dc == 59)	begin
								offset_bo[0][bo_cate] <= 0;
								offset_bo[1][bo_cate] <= 0;
							end
							else */if(bo_cate== cnt_dc-16 && cnt_dc<48-SHIFT && idx == cIdx[1])
								offset_bo[idx][bo_cate] <= init_offset;
						end
					end
			end
		end
		
	endgenerate
	
	
endmodule