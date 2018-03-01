module sao_stat_n_add_s41
	#(
		parameter PIX4 = 4,
		parameter diff_clip_bit = 4,
		parameter n_bo_type = 5)
	(
		input 	logic													clk,rst_n,arst_n,
		input 	logic 				[n_bo_type-1:0]						cate_target,	
		input 	logic 				[n_bo_type-1:0]						cate [0:PIX4-1],	
		input 	logic   signed 		[diff_clip_bit:0]					diff[0:PIX4-1],
		input	logic 													isWorking_stat,en,

		output 	logic 	signed 		[diff_clip_bit+2:0]					s41
	);
	logic signed [diff_clip_bit+1:0]		s2_a,s2_b;
	logic signed [diff_clip_bit+1:0]		s2_a_,s2_b_;

	always_comb begin : proc_
		{s41} = 0;
		s41 = s2_a_ + s2_b_; 
	end
		
sao_stat_n_add_s21 #(.n_bo_type(n_bo_type)) s21_a(
	.cate_target(cate_target),
	.cate(cate [0:1]),
	.diff(diff[0:1]),
	.s21(s2_a),
	.*
	);

sao_stat_n_add_s21 #(.n_bo_type(n_bo_type)) s21_b(
	.cate_target(cate_target),
	.cate(cate [2:3]),
	.diff(diff[2:3]),
	.s21(s2_b),
	.*
	);


always_ff @(posedge clk or negedge arst_n)
	if(!arst_n) begin
		{s2_a_,s2_b_} <=0;
	end
	else if(!rst_n) begin
		{s2_a_,s2_b_} <=0;
	end
	else begin
		if(isWorking_stat & en) begin
			{s2_a_,s2_b_} <= {s2_a,s2_b};
		end
	
	end
endmodule // sao_stat_n_add_s41