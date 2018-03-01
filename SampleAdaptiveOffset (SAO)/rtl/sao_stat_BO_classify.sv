`timescale 1ns/1ps
module sao_stat_BO_classify #(
parameter bit_depth = 8
)
(
	input logic [bit_depth-1:0] 	rec,
	output logic  [4:0]	bo_catagory
);

	assign bo_catagory = rec[bit_depth-1:bit_depth-5];
	
endmodule
