`timescale 1ns/1ps
module sao_stat_EO_classify #(
parameter bit_depth = 8
)
(
	input logic signed [1:0] 	sign_l,
	input logic signed [1:0] 	sign_r,
	output logic  [2:0]	eo_catagory
);

	logic [2:0] 	edgeIdx;
	assign edgeIdx=sign_l+sign_r+2;
	
	always_comb begin
		eo_catagory = 4;
		case (edgeIdx)
			3'd0:eo_catagory = 1;
			3'd1:eo_catagory = 2;
			3'd2:eo_catagory = 0;
			3'd3:eo_catagory = 3;
			default: eo_catagory = 4;
		endcase
	end

endmodule
