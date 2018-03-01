`timescale 1ns/1ps
module sao_deci_dist_accu #(
	parameter offset_len = 4,
	parameter dist_len = 21,
	parameter num_pix_CTU_log2 = 5,
	parameter num_accu_len = num_pix_CTU_log2*2-1,
	parameter num_CTU = num_accu_len,
	parameter sum_CTU = 16,
	parameter num_category = 4
	)
(

	input logic 						clk,
	input logic 						arst_n,
	input logic 						rst_n,
	input logic 						en,
	input logic signed [dist_len-1:0] distortion,
	output logic signed [dist_len-1+num_category:0] dist_one_type	
);



logic b_accu;
logic [2:0]  cnt;

assign b_accu = (cnt<num_category);

always_ff @(posedge clk or negedge arst_n) begin

	if(!arst_n) 
		{dist_one_type,cnt} <= 0;
	else if(!rst_n)
		{dist_one_type,cnt} <= 0;
	else begin
		if(en) begin
			if(b_accu) begin
				dist_one_type <= dist_one_type + distortion;
				cnt <= cnt + 1 ;
			end
			else begin
				dist_one_type <= 0;
				cnt <= 0;
			end
		end
	end

end

endmodule