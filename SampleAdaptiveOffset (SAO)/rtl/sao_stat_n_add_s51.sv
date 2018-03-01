module sao_stat_n_add_s51
	#(
		parameter PIX5 = 5,
		parameter diff_clip_bit = 4,
		parameter n_bo_type = 5)
	(
		input 	logic													clk,rst_n,arst_n,
		input 	logic 				[n_bo_type-1:0]								cate_target,		
		input 	logic 				[n_bo_type-1:0]								cate [0:PIX5-1],	
		input 	logic   signed 		[diff_clip_bit:0]					diff[0:PIX5-1],
		input	logic 													isWorking_stat,en,

		output 	logic 	signed 		[diff_clip_bit+3:0]					s51
	);
	logic signed [diff_clip_bit+1:0]		s2_a;
	logic signed [diff_clip_bit+1:0]		s2_a_;
	logic signed [diff_clip_bit+2:0]		s3_a;

	always_comb begin : proc_
		{s51} = 0;
		s51 = s2_a_ + s3_a; 
	end
		
sao_stat_n_add_s21 #(.n_bo_type(n_bo_type)) s21_a(
	.cate_target,
	.cate(cate[0:1]),
	.diff(diff[0:1]),
	.s21(s2_a),
	.*
	);

sao_stat_n_add_s31  #(.n_bo_type(n_bo_type)) s31_a(
	.cate_target,
	.cate(cate[2:4]),
	.diff(diff[2:4]),
	.s31(s3_a),
	.*
	);

always_ff @(posedge clk or negedge arst_n)
	if(!arst_n) begin
		{s2_a_} <=0;
	end
	else if(!rst_n) begin
		{s2_a_} <=0;
	end
	else begin
		if(isWorking_stat & en) begin
			{s2_a_} <= {s2_a};
		end
	
	end

endmodule // sao_stat_n_add_s41