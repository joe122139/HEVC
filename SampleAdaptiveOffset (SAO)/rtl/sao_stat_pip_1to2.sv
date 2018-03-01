`timescale 1ns/1ps
`ifndef P7_BO_REDUCED
`define P7_BO_REDUCED 1
`endif

module sao_stat_pip_1to2 #(
parameter diff_clip_bit = 4,
parameter n_pix = 4
)
(
	input 	logic				clk,arst_n,rst_n,en_i,en_o,
	input 	logic				isWorking_stat,
	input   logic 				wait_forPre,
	input	logic				not_end,
	input	logic				not_end_pre_stage,
//	input	logic		[4:0]	cand_bo,
	input  	logic 	signed 	[diff_clip_bit:0]					n_diff[0:n_pix-1],
	input	logic		[1:0]	cIdx,
	
	output	logic				not_end_r1,
`ifdef P7_BO_REDUCED
	output	logic				not_end_pre_stage_r1,
`endif
	output  logic 				isWorking_stat_r1,
	output   logic 				wait_forPre_r1,
	output  logic 	signed 	[diff_clip_bit:0]					n_diff_r1[0:n_pix-1],
//	output	logic		[4:0]	cand_bo_r1,
	output	logic		[1:0]	cIdx_r1
);
always_ff @(posedge clk or negedge arst_n)
	if(!arst_n) begin
		isWorking_stat_r1 <= 0;
		wait_forPre_r1 <=0;
		{n_diff_r1[0],n_diff_r1[1],n_diff_r1[2],n_diff_r1[3]} <=0;
		`ifdef PIX_8
		{n_diff_r1[4],n_diff_r1[5],n_diff_r1[6],n_diff_r1[7]} <=0;
		`endif
		not_end_r1 <= 0;
`ifdef P7_BO_REDUCED
		not_end_pre_stage_r1 <= 0;
//		cand_bo_r1 <= 0;
		cIdx_r1 <= 0 ;
`endif
	end
	else if (!rst_n) begin
		isWorking_stat_r1 <= 0;
		wait_forPre_r1 <=0;
		{n_diff_r1[0],n_diff_r1[1],n_diff_r1[2],n_diff_r1[3]} <=0;
		`ifdef PIX_8
		{n_diff_r1[4],n_diff_r1[5],n_diff_r1[6],n_diff_r1[7]} <=0;
		`endif
		not_end_r1 <= 0;
`ifdef P7_BO_REDUCED
		not_end_pre_stage_r1 <= 0;
//		cand_bo_r1 <= 0;
		cIdx_r1 <= 0 ;
`endif
	end 
	else begin
		if(en_o)	begin
			isWorking_stat_r1 <= isWorking_stat;
			{n_diff_r1[0],n_diff_r1[1],n_diff_r1[2],n_diff_r1[3]} <= {n_diff[0],n_diff[1],n_diff[2],n_diff[3]};
			`ifdef PIX_8
			{n_diff_r1[4],n_diff_r1[5],n_diff_r1[6],n_diff_r1[7]} <= {n_diff[4],n_diff[5],n_diff[6],n_diff[7]};
			`endif
			not_end_r1 		<=	not_end;
			wait_forPre_r1 	<=	wait_forPre;
`ifdef P7_BO_REDUCED
			not_end_pre_stage_r1 <= not_end_pre_stage;
//			cand_bo_r1 <= cand_bo;
			cIdx_r1 <= cIdx ;
`endif
		end
	end
endmodule