module sao_stat_n_add_s11
	#(
		parameter PIX2 = 2,
		parameter diff_clip_bit = 4,
		parameter n_bo_type = 5)
	(
		input 	logic 				[n_bo_type-1:0]								cate_target,		
		input 	logic 				[n_bo_type-1:0]								cate ,	
		input 	logic 	signed		[diff_clip_bit:0]					diff,
		output 	logic 	signed 		[diff_clip_bit:0]					s11
	);
	always_comb begin : proc_
		{s11} = 0;
		s11 = ( cate_target== cate)? diff:0;
	end	

	endmodule // sao_stat_n_add_s21