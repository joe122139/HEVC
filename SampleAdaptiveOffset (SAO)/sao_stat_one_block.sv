module sao_stat_one_block
#(
parameter bit_depth = 8, 
parameter type sample = logic [bit_depth-1:0], 
parameter type sign_sample = logic [bit_depth:0])
(
	input 	sample 				rec_l[0:3][0:3],
	input 	sample 				rec_r[0:3][0:3],
	input 	sample 				rec_m[0:3][0:3],
	input 	sample 				org_m[0:3][0:3],
	output logic signed [1:0] 	sign_l[0:3][0:3],
	output logic signed [1:0] 	sign_r[0:3][0:3],
	output logic signed [4:0]	diff[0:3][0:3]
);

parameter [2:0] diff_clip_bit = 4;
	//sao_stat_one_pixel sao_stat_one_pixel (.*);
	//#(.sample(sample),.sign_sample(sign_sample))

generate
for(genvar i=0;i<4;i++) begin
	for(genvar j=0;j<4;j++) begin
		sao_stat_one_pixel sao_stat_one_pixel(
		.rec_l(rec_l[i][j]), 
		.rec_r(rec_r[i][j]), 
		.rec_m(rec_m[i][j]), 
		.org_m(org_m[i][j]), 
		.sign_l(sign_l[i][j]), 
		.sign_r(sign_r[i][j]), 
		.diff(diff[i][j]) 
		);
	end
end
endgenerate
//	sao_stat_one_pixel sao_stat_one_pixel (.*);

endmodule
