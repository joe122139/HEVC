module sao_stat_n_add_s61
	#(
		parameter PIX6 = 6,
		parameter diff_clip_bit = 4,
	parameter n_bo_type = 5)
	(
		input 	logic													clk,rst_n,arst_n,
		input 	logic 				[n_bo_type-1:0]								cate_target,		
		input 	logic 				[n_bo_type-1:0]								cate [0:PIX6-1],	
		input 	logic   signed 		[diff_clip_bit:0]					diff[0:PIX6-1],
		input	logic 													isWorking_stat,en,

		output 	logic 	signed 		[diff_clip_bit+3:0]					s61
	);
	logic signed [diff_clip_bit+2:0]		s3_a;
	logic signed [diff_clip_bit+2:0]		s3_b;

	always_comb begin : proc_
		{s61} = 0;
		s61 = s3_b + s3_a; 
	end
		
sao_stat_n_add_s31 #(.n_bo_type(n_bo_type)) s31_a(
	.cate_target,
	.cate(cate [0:2]),
	.diff(diff[0:2]),
	.s31(s3_a),
	.*
	);

sao_stat_n_add_s31 #(.n_bo_type(n_bo_type)) s31_b(
	.cate_target,
	.cate(cate [3:5]),
	.diff(diff[3:5]),
	.s31(s3_b),
	.*
	);

endmodule // sao_stat_n_add_s41