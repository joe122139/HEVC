`timescale 1ns/1ps
module sao_deci_dist #(
	parameter offset_len = 4,
	parameter dist_len = 21,
	parameter num_pix_CTU_log2 = 5,
	parameter num_accu_len = num_pix_CTU_log2*2-1,
	parameter num_CTU = num_accu_len+1,
	parameter diff_clip_bit = 4,
	parameter sum_CTU = num_accu_len+diff_clip_bit+1,
	parameter o_o_len = (offset_len-1)*2
)
(
	input logic	signed  [offset_len-1:0] u_offset,
	input logic [num_CTU-1:0] num_blk_CTU,
	input logic signed [sum_CTU-1:0] sum_blk_CTU,
	output logic signed [dist_len-1:0] distortion
);

logic [o_o_len+num_CTU-1:0] o_o_n;
logic signed [offset_len+sum_CTU:0] o_2s;
logic [o_o_len-1:0]	o_o;
logic [offset_len-2:0]	unsign_o;

assign unsign_o = u_offset[offset_len-1]? (~u_offset+1):u_offset[offset_len-2:0];
assign o_o = unsign_o * unsign_o;
assign o_o_n = o_o*num_blk_CTU;
assign o_2s = (u_offset*sum_blk_CTU)<<1;
assign distortion = $signed({1'b0,o_o_n}) - o_2s;

endmodule