`timescale 1ns/1ps
`define PIX_8

module sao_top_clk #(
	parameter diff_clip_bit = 4,
	parameter n_category = 4,
	parameter n_category_bo = 8,
	parameter num_pix_CTU_log2 = 5,
	parameter num_accu_len = num_pix_CTU_log2*2-1,
	parameter blk_22_X_len = 6,
	parameter blk_22_Y_len = 6,
	`ifdef PIX_8
	parameter n_pix = 8,
	parameter org_window_width = 4,
	`else 
	parameter n_pix = 4,
	parameter org_window_width = 2,
	`endif
	parameter org_window_height = n_pix/org_window_width,
	parameter bit_depth = 8,
	parameter pic_width_len = 13,
	parameter pic_height_len = 13,
	parameter cnt_st_len = 10,
	parameter cnt_dc_len = 6,
	parameter isChroma  = 0,
	parameter cut_x_len = 9,
	parameter cut_y_len = 9,
	
parameter n_eo_type = 4,
parameter sao_type_len = 3,
parameter offset_len = 4
	
)(
	input logic 									clk,arst_n,rst_n,
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
	output	logic 			[1:0]    												sao_mode[0:1],					//0£º OFF    1:NEW   2:MERGE
	output	logic 			[$clog2(32)-1:0]   										typeAuxInfo[0:2],
	
	output	logic 	signed [num_accu_len+diff_clip_bit:0]							sum_blk_CTU[0:n_eo_type-1][0:n_category-1],
	output	logic 			[num_accu_len:0]										num_blk_CTU[0:n_eo_type-1][0:n_category-1],

	output	logic 	signed [num_accu_len+diff_clip_bit:0]							sum_blk_CTU_bo[0:n_category_bo-1],
	output	logic 			[num_accu_len:0]										num_blk_CTU_bo[0:n_category_bo-1],
	
	output	logic   								wait_forPre,
	output	logic	[1:0]							cIdx,
	output   logic			[9:0]														cnt_st,
	output   logic			[5:0]														cnt_dc,
	output   logic			[1:0]														cIdx_dc
	);
	
	logic  clk_slow,clk_fast;
	sao_top #(.num_pix_CTU_log2(num_pix_CTU_log2),.num_accu_len(num_accu_len), .n_pix(n_pix), .org_window_width(org_window_width) ) sao_top(
	.clk(clk_fast),
	.clk_slow,
//	.Y_,
	.*
	);
	
	sao_clk_gen sao_clk_gen(
		.clk,
		.clk_slow,
		.clk_fast,
		.*
	);
	
	
endmodule