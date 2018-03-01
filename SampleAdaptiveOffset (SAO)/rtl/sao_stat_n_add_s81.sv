module sao_stat_n_add_s81
	#(
		parameter PIX8 = 8,
		parameter diff_clip_bit = 4,
		parameter n_bo_type = 5)
	(
		input 	logic													clk,rst_n,arst_n,
		input 	logic 				[n_bo_type-1:0]						cate_target,		
		input 	logic 				[n_bo_type-1:0]						cate [0:PIX8-1],	
		input 	logic   signed 		[diff_clip_bit:0]					diff[0:PIX8-1],
		input	logic 													isWorking_stat,en,

		output 	logic 	signed 		[diff_clip_bit+3:0]					s81
	);
	logic signed [diff_clip_bit+2:0]		s4_b;
	logic signed [diff_clip_bit+2:0]		s4_a;

	always_comb begin : proc_
		{s81} = 0;
		s81 = s4_a + s4_b; 
	end
		
sao_stat_n_add_s41 #(.n_bo_type(n_bo_type)) s41_a(
	.cate_target,
	.cate(cate[0:3]),
	.diff(diff[0:3]),
	.s41(s4_a),
	.*
	);

sao_stat_n_add_s41 #(.n_bo_type(n_bo_type)) s41_b(
	.cate_target,
	.cate(cate [4:7]),
	.diff(diff[4:7]),
	.s41(s4_b),
	.*
	);

endmodule // sao_stat_n_add_s41