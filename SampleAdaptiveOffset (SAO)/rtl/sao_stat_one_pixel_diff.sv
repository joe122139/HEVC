`timescale 1ns/1ps
module sao_stat_one_pixel_diff #(
parameter bit_depth = 8,
parameter diff_clip_bit = 4//,
//parameter type sample = logic [bit_depth-1:0],
//parameter type sign_sample = logic [bit_depth:0]
)
(
///	sao_if.PIX_DIFF i
	input 	[bit_depth-1:0] 				rec_m,
	input 	[bit_depth-1:0] 				org_m,
	output logic signed [diff_clip_bit:0]	diff
);

	logic [bit_depth:0] diff_unclip;
 //   assign diff_unclip = i.org_m - i.rec_m;
    assign diff_unclip = org_m - rec_m;
	always_comb begin
	/*	i.diff = diff_unclip[diff_clip_bit:0];
		if(diff_unclip <= ((-1)<<<diff_clip_bit))
			i.diff = (-1)<<<diff_clip_bit+1;
		if (diff_unclip >= (1<<diff_clip_bit))
			i.diff = (1<<diff_clip_bit)-1;
	*/		
		diff = diff_unclip[diff_clip_bit:0];
		if($signed(diff_unclip) <= ((-1)<<<diff_clip_bit))
			diff = ((-1)<<<diff_clip_bit)+1;
		if ($signed(diff_unclip) >= (1<<diff_clip_bit))
			diff = (1<<diff_clip_bit)-1;
	end

endmodule
