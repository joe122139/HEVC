`timescale 1ns/1ps
//`define PIX_8
module sao_stat_n_pix_add
#(
parameter diff_clip_bit = 4,
`ifdef PIX_8
parameter n_pix=8,
`else
parameter n_pix=4,
`endif
parameter EO_CATEGORY_F_V = 0,
parameter EO_CATEGORY_H_V = 1,
parameter EO_CATEGORY_H_P = 2,
parameter EO_CATEGORY_F_P = 3,
parameter n_bo_type = 5
)
(
	//sao_if.n_ADD it
	input 	logic												clk,rst_n,arst_n,en,
	input 	logic signed 	[diff_clip_bit:0]					n_diff[0:n_pix-1],
	input 	logic 			[n_bo_type-1:0]						cate [0:n_pix-1],
	input	logic 												isWorking_stat,
	input	[n_pix-1:0]											b_use,
	output logic signed 	[diff_clip_bit+2:0]					s41,
	output logic signed 	[diff_clip_bit+2:0]					s31,
	output logic signed 	[diff_clip_bit+1:0]					s21,
	output logic signed 	[diff_clip_bit:0]					s11
`ifdef PIX_8
	,output logic signed 	[diff_clip_bit+3:0]					s51,
	output logic signed 	[diff_clip_bit+3:0]					s61,
	output logic signed 	[diff_clip_bit+3:0]					s71,
	output logic signed 	[diff_clip_bit+3:0]					s81 
`endif
);


logic signed [diff_clip_bit+1:0]		s2_a,s2_b,s2_a_;
logic signed [diff_clip_bit:0]			b0,c0,d0;
logic signed [diff_clip_bit:0]			c1,d1;
logic signed [diff_clip_bit:0]			d2;
logic signed [diff_clip_bit:0]			diff[0:n_pix-1];
logic signed [diff_clip_bit:0]			diff_2,diff_3;
logic signed [diff_clip_bit+1:0]		s21_c;
logic signed [diff_clip_bit:0]			s11_c;

always_comb begin
	diff[0] = b_use[0]? n_diff[0]:0;
	diff[1] = b_use[1]? n_diff[1]:0;
	diff[2] = b_use[2]? n_diff[2]:0;
	diff[3] = b_use[3]? n_diff[3]:0;
end

`ifdef PIX_8
always_comb begin
	diff[4] = b_use[4]? n_diff[4]:0;
	diff[5] = b_use[5]? n_diff[5]:0;
	diff[6] = b_use[6]? n_diff[6]:0;
	diff[7] = b_use[7]? n_diff[7]:0;
end

always_ff @(posedge clk or negedge arst_n) 
	if(~arst_n) begin
		 {s11,s21}<= 0;
    end else if(~rst_n) begin
		 {s11,s21}<= 0;
	end else begin
		 {s11,s21}<= {s11_c,s21_c};
	end

sao_stat_n_add_s11 #(.n_bo_type(n_bo_type)) c11(
	.cate_target(cate[7]),
	.cate(cate[7]),
	.diff(diff[7]),
	.s11(s11_c),
	.*);
sao_stat_n_add_s21 #(.n_bo_type(n_bo_type)) c21(
	.cate_target(cate[6]),
	.cate(cate[6:7]),
	.diff(diff[6:7]),
	.s21(s21_c),
	.*);
sao_stat_n_add_s31 #(.n_bo_type(n_bo_type)) c31(
	.cate_target(cate[5]),
	.cate(cate[5:7]),
	.diff(diff[5:7]),
	.*);
sao_stat_n_add_s41 #(.n_bo_type(n_bo_type)) c41(
	.cate_target(cate[4]),
	.cate(cate[4:7]),
	.diff(diff[4:7]),
	.*);

sao_stat_n_add_s51 #(.n_bo_type(n_bo_type)) c51(
	.cate_target(cate[3]),
	.cate(cate[3:7]),
	.diff(diff[3:7]),
	.*);
sao_stat_n_add_s61 #(.n_bo_type(n_bo_type)) c61(
	.cate_target(cate[2]),
	.cate(cate[2:7]),
	.diff(diff[2:7]),
	.*);
sao_stat_n_add_s71 #(.n_bo_type(n_bo_type)) c71(
	.cate_target(cate[1]),
	.cate(cate[1:7]),
	.diff(diff[1:7]),
	.*);
sao_stat_n_add_s81 #(.n_bo_type(n_bo_type)) c81(
	.cate_target(cate[0]),
	.cate(cate[0:7]),
	.diff(diff[0:7]),
	.*);




`else
always_comb begin
	{b0,c0,d0,c1} = 0;
	{s41,s31,s21,s11} = 0;
	if(isWorking_stat)	begin
		b0 = ( cate[0]== cate[1])? diff[1]:0;
		c0 = ( cate[0]== cate[2])? diff[2]:0;
		d0 = ( cate[0]== cate[3])? diff[3]:0;

		c1 = ( cate[1]== cate[2])? diff[2]:0;
	
		s41 = s2_a_ + s2_a; 
		s31 = s2_b + d1; 

		s21 = diff_2 + d2;
		s11 = diff_3;
	 end

end

always_ff @(posedge clk or negedge arst_n)
	if(!arst_n) begin
	//	{sA,sB,sC,sD}<= 0;
	{s2_a_,s2_b,s2_a,d1,d2,diff_2,diff_3}<=0;
	end
	else if(!rst_n) begin
	//	{sA,sB,sC,sD}<= 0;
	{s2_a_,s2_b,s2_a,d1,d2,diff_2,diff_3}<=0;
	end
	else begin
		if(isWorking_stat & en) begin
			s2_a_ <= d0 + c0; 
			s2_b <= diff[1] + c1 ; 
			s2_a <=diff[0] + b0 ; 
			d1 <= ( cate[1]== cate[3])? diff[3]:0;
			 d2 <= ( cate[2]== cate[3])? diff[3]:0;
			diff_2 <= diff[2]; 
			diff_3 <= diff[3]; 
	/*		 sA <= s2_a_ + s2_a; 
			 sB <= s2_b + d1; 
			 sC <= diff[2] + d2;
			 sD <= diff[3];*/
		end
	
	end

`endif
endmodule
