module sao_stat_one_pixel #(
parameter bit_depth = 8,
parameter type sample = logic [bit_depth-1:0], 
parameter type sign_sample = logic [bit_depth:0])
(
	input 	sample 				rec_l,
	input 	sample 				rec_r,
	input 	sample 				rec_m,
	input 	sample 				org_m,
	output logic signed [1:0] 	sign_l,
	output logic signed [1:0] 	sign_r,
	output logic signed [4:0]	diff
);

parameter [2:0] diff_clip_bit = 4;
	sign_sample diff_unclip;
    assign diff_unclip = org_m - rec_m;
	always_comb begin
		diff = diff_unclip[4:0];
		if(diff_unclip <= ((-1)<<<diff_clip_bit))
			diff = (-1)<<<diff_clip_bit+1;
		if (diff_unclip >= (1<<diff_clip_bit))
			diff = (1<<diff_clip_bit)-1;
	end
	
	always_comb begin
		sign_l = (rec_m > rec_l)? 1: rec_m == rec_l ? 0 : -1;
		sign_r = (rec_m > rec_r)? 1: rec_m == rec_l ? 0 : -1;
	end

endmodule
