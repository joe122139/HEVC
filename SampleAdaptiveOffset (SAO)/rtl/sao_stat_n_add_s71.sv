module sao_stat_n_add_s71
	#(
		parameter PIX7 = 7,
		parameter diff_clip_bit = 4,
		parameter n_bo_type = 5)
	(
		input 	logic													clk,rst_n,arst_n,
		input 	logic 				[n_bo_type-1:0]						cate_target,		
		input 	logic 				[n_bo_type-1:0]						cate [0:PIX7-1],	
		input 	logic   signed 		[diff_clip_bit:0]					diff[0:PIX7-1],
		input	logic 													isWorking_stat,en,

		output 	logic 	signed 		[diff_clip_bit+3:0]					s71
	);
	logic signed [diff_clip_bit+2:0]		s3_a;
	logic signed [diff_clip_bit+2:0]		s4_a;

	always_comb begin : proc_
		{s71} = 0;
		s71 = s4_a + s3_a; 
	end
		
sao_stat_n_add_s31 #(.n_bo_type(n_bo_type)) s31_a(
	.cate_target,
	.cate(cate [0:2]),
	.diff(diff[0:2]),
	.s31(s3_a),
	.*
	);

sao_stat_n_add_s41 #(.n_bo_type(n_bo_type)) s41_a(
	.cate_target,
	.cate(cate [3:6]),
	.diff(diff[3:6]),
	.s41(s4_a),
	.*
	);

endmodule // sao_stat_n_add_s41