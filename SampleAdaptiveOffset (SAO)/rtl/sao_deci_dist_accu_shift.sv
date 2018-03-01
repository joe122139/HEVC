`timescale 1ns/1ps
module sao_deci_dist_accu_shift #(
	parameter offset_len = 4,
	parameter dist_len = 21,
	parameter num_category = 4,
	parameter eo_bo_type_len = 5,
	parameter SHIFT = 24
	)
(
	input logic 											clk,
	input logic 											arst_n,
	input logic 											rst_n,
	input logic 											en,
	input logic 	signed 	[dist_len-1:0] 					distortion,
	input	logic 			[5:0]  							cnt,
	input	logic											isLeftMergeAvail,
	input	logic											isUpperMergeAvail,
	
	output	logic 			[5:0]  							cnt_r1,
	output logic 	signed 	[dist_len-1+num_category:0] 	dist_one_type,	
	output logic 	signed 	[dist_len-1+num_category:0] 	dist_bo_type_best,	

	output logic			[2:0]			best_bo_category
);


logic	signed	[dist_len-1:0]	distn[0:3];
logic 	signed 	[dist_len:0] 	distn_x[0:1];
logic 	signed [dist_len+1:0] 	distn_xx;


logic 														b_accu;
logic				[2:0]					bo_cate;
		
assign b_accu = ((cnt<17 || cnt>48-SHIFT) && cnt%4==0) || (cnt>18 && cnt<=48-SHIFT);

always_ff @(posedge clk or negedge arst_n) 

	if(!arst_n) begin
	/*	dist_one_type <= {1'b0,24'hffff};
		distn[0] <= {1'b0,20'hffff};
		distn[1] <= {1'b0,20'hffff};
		distn[2] <= {1'b0,20'hffff};
		distn[3] <= {1'b0,20'hffff};
		dist_one_type <= {1'b0,24'hffff};*/
		{dist_one_type,distn[0],distn[1],distn[2],distn[3]} <=0;
		dist_bo_type_best <= {1'b0,24'hffff};
		{bo_cate} <= 0;
		cnt_r1 <= 0;
		
		end
	else if(!rst_n) begin
/*		dist_one_type <= {1'b0,24'hffff};
		distn[0] <= {1'b0,20'hffff};
		distn[1] <= {1'b0,20'hffff};
		distn[2] <= {1'b0,20'hffff};
		distn[3] <= {1'b0,20'hffff};
		dist_one_type <= {1'b0,24'hffff};*/
		{dist_one_type,distn[0],distn[1],distn[2],distn[3]} <=0;
		dist_bo_type_best <= {1'b0,24'hffff};
		{bo_cate} <= 0;
		cnt_r1 <= 0;
		end
	else begin
		if(en) begin
			cnt_r1<= cnt;
			{distn[0],distn[1],distn[2],distn[3]} <= {distortion,distn[0],distn[1],distn[2]};
			if(b_accu) begin
				dist_one_type <= distn_xx;	
			end
			else begin
			//	dist_one_type <=  {1'b0,24'hffff};
				dist_one_type <=  0;
			end
			
			bo_cate <= cnt>15 && cnt<48-SHIFT? (cnt-5'd16):0;
			
			if(cnt==0) begin
				dist_bo_type_best <= 0;
				best_bo_category 	<=	0;
			end
		//	else if(distn_xx < dist_bo_type_best && bo_cate>3 && b_accu) begin
			else if(distn_xx < dist_bo_type_best && bo_cate>2 && b_accu) begin
				{dist_bo_type_best} <= 	distn_xx;		//!dist_bo_type_best is reset to 0, when cIdx becomes 1.
				best_bo_category 	<=	bo_cate-3;
			end
		end
	end


always_comb begin
	distn_x[0] = distn[0]	+	distn[1];
	distn_x[1] = distn[2]	+	distn[3];
	distn_xx   = distn_x[0]	+	distn_x[1];
	
end


endmodule