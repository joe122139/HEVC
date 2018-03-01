`timescale 1ns/1ps
module sao_stat_n_pix_add_bo
#(
parameter diff_clip_bit = 4,
parameter n_pix=4,
parameter n_bo_type = 5
)
(
	//sao_if.n_ADD it
	input	logic												clk,rst_n,arst_n,en,
	input 	logic signed 	[diff_clip_bit:0]					n_diff[0:n_pix-1],
	input 	logic 			[n_bo_type-1:0]						bo_cate [0:n_pix-1],
	input	[n_pix-1:0]											b_use,
	input	logic 												isWorking_stat,
	output logic signed 	[diff_clip_bit+2:0]					s41,
	output logic signed 	[diff_clip_bit+2:0]					s31,
	output logic signed 	[diff_clip_bit+1:0]					s21,
	output logic signed 	[diff_clip_bit:0]					s11
);
/*
sss 0   --- 012
sss 1   --- 013
sss 2   --- 023
sss 3   --- 123
*/

logic signed [diff_clip_bit+1:0]		s2_a,s2_b,s2_a_;
logic signed [diff_clip_bit+2:0]		s3_a;
logic signed [diff_clip_bit:0]			b0,c0,d0;
logic signed [diff_clip_bit:0]			c1,d1;
logic signed [diff_clip_bit:0]			d2;
logic signed [diff_clip_bit:0]			diff[0:n_pix-1];
logic signed [diff_clip_bit:0]			diff_2,diff_3;


always_comb begin
	diff[0] = b_use[0]? n_diff[0]:0;
	diff[1] = b_use[1]? n_diff[1]:0;
	diff[2] = b_use[2]? n_diff[2]:0;
	diff[3] = b_use[3]? n_diff[3]:0;
	
	{b0,c0,d0,c1} = 0;
	{s41,s31,s21,s11} = 0;
	if(isWorking_stat)	begin
		b0 = ( bo_cate[0]== bo_cate[1])? diff[1]:0;
		c0 = ( bo_cate[0]== bo_cate[2])? diff[2]:0;
		d0 = ( bo_cate[0]== bo_cate[3])? diff[3]:0;

		
		
		c1 = ( bo_cate[1]== bo_cate[2])? diff[2]:0;

		
		s41 = s2_a_ + s2_a; 
		 s31 = s2_b + d1; 


		s21 = diff_2 + d2;
		 s11 = diff_3;
	 end

end

always_ff @(posedge clk or negedge arst_n)
	if(!arst_n) begin
	{s2_a_,s2_b,s2_a,d1,d2,diff_2,diff_3}<=0;
	end
	else if(!rst_n) begin
	{s2_a_,s2_b,s2_a,d1,d2,diff_2,diff_3}<=0;
	end
	else begin
		if(isWorking_stat & en) begin
			s2_a_ <= d0 + c0; 
			s2_b <= diff[1] + c1 ; 
			s2_a <=diff[0] + b0 ; 
			d1 <= ( bo_cate[1]== bo_cate[3])? diff[3]:0;
			 d2 <= ( bo_cate[2]== bo_cate[3])? diff[3]:0;
			diff_2 <= diff[2]; 
			diff_3 <= diff[3]; 
		end
	
	end
endmodule
