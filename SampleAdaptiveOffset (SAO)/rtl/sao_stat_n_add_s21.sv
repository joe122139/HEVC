module sao_stat_n_add_s21
	#(
		parameter PIX2 = 2,
		parameter diff_clip_bit = 4,
		parameter n_bo_type = 5)
	(
	input 	logic													clk,rst_n,arst_n,		
	input 	logic 				[n_bo_type-1:0]						cate_target,		
	input 	logic 				[n_bo_type-1:0]						cate [0:PIX2-1],	
	input 	logic 	signed		[diff_clip_bit:0]					diff[0:PIX2-1],
	input   logic													isWorking_stat,
	input   logic													en,
	output 	logic 	signed 		[diff_clip_bit+1:0]					s21
	);
		
		logic signed [diff_clip_bit:0]			c0,d0;

		sao_stat_n_add_s11 #(.n_bo_type(n_bo_type)) s1(
			.cate_target,
			.cate(cate[0]),
			.diff(diff[0]),
			.s11(c0),
			.*);
		sao_stat_n_add_s11 #(.n_bo_type(n_bo_type)) s2(
			.cate_target,
			.cate(cate[1]),
			.diff(diff[1]),
			.s11(d0),
			.*);
assign s21 = d0 +c0;

	endmodule // sao_stat_n_add_s21