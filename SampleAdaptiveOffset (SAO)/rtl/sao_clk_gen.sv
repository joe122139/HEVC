`timescale 1ns/1ps
module sao_clk_gen #(
	parameter MULT = 3
)
(
	input	logic	clk,rst_n,arst_n,
	output	logic	clk_slow,
	output	logic	clk_fast
);


logic	[1:0]	cnt;

always_ff @(posedge clk or negedge arst_n)
	if(!arst_n) 
		{cnt,clk_slow}<=0;
	else if(!rst_n)
		{cnt,clk_slow}<=0;
	else begin
		if(cnt==MULT-1) begin
			clk_slow <= !clk_slow;
			cnt <=0;
		end
		else
			cnt <= cnt+1;
	end

	
always_comb 
	begin
		{clk_fast}=clk;
	end
/*
always_ff @(posedge clk or negedge arst_n)
	if(!arst_n) 
		{clk_fast}<=0;
	else if(!rst_n)
		{clk_fast}<=0;
	else begin
		{clk_fast}<=clk;
	end*/
endmodule