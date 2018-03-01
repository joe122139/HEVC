`timescale 1ns/1ps
module sao_stat_one_pixel_cmp #(
parameter bit_depth = 8//,
//parameter type sample = logic [8-1:0]
)
(
//	sao_if.PIX_CMP i
	input 	logic [8-1:0] 				rec_l,
	input 	logic [8-1:0] 				rec_r,
	input 	logic [8-1:0] 				rec_m,
	output logic signed [1:0] 	sign_l,
	output logic signed [1:0] 	sign_r
);
	
	always_comb begin
	/*	i.sign_l = (i.rec_m > i.rec_l)? 1: i.rec_m == i.rec_l ? 0 : -1;
		i.sign_r = (i.rec_m > i.rec_r)? 1: i.rec_m == i.rec_l ? 0 : -1;*/
		
		sign_l = (rec_m > rec_l)? 1: rec_m == rec_l ? 0 : -1;
		sign_r = (rec_m > rec_r)? 1: rec_m == rec_r ? 0 : -1;
	end

endmodule
