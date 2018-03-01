module sao_stat_n_add_s31
	#(
		parameter PIX3 = 3,
		parameter diff_clip_bit = 4,
		parameter n_bo_type = 5)
	(
	input 	logic													clk,rst_n,arst_n,		
	input 	logic 				[n_bo_type-1:0]						cate_target,		
	input 	logic 				[n_bo_type-1:0]						cate[0:PIX3-1],	
	input 	logic 	signed		[diff_clip_bit:0]					diff[0:PIX3-1],
	input   logic													isWorking_stat,
	input   logic													en,
	output 	logic 	signed 		[diff_clip_bit+2:0]					s31
	);
		
		logic signed [diff_clip_bit:0]				c0,c0_;
		logic signed [diff_clip_bit+1:0]			s2_a,s2_a_;

		sao_stat_n_add_s11 #(.n_bo_type(n_bo_type)) s1(
			.cate_target,
			.cate(cate[0]),
			.diff(diff[0]),
			.s11(c0),
			.*);

		sao_stat_n_add_s21 #(.n_bo_type(n_bo_type)) s21_a(
			.cate_target,
			.cate(cate[1:2]),
			.diff(diff[1:2]),
			.s21(s2_a),
			.*
		);

assign s31 = c0_+s2_a_;

always_ff @(posedge clk or negedge arst_n)
	if(!arst_n) begin
		{c0_,s2_a_} <=0;
	end
	else if(!rst_n) begin
		{c0_,s2_a_} <=0;
	end
	else begin
		if(isWorking_stat & en) begin
			{c0_,s2_a_} <= {c0,s2_a};
		end
	
	end

endmodule // sao_stat_n_add_s21