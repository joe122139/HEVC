`timescale 1ns/1ps
module sao_deci_cost #(
	parameter dist_len = 21,
	parameter num_category = 4,
	parameter lamda_len = 9,
	parameter n_category_bo = 32,
	parameter n_sao_type = 3,
	parameter rate_len = 5,
	parameter eo_bo_type_len = 5,
	parameter n_total_type = 5,		//0~3,EO;  4,BO; 
	parameter SHIFT =24
)
(
	input	logic												clk,rst_n,arst_n,en_o,
	input 	logic	[1:0]										cIdx,
	input 	logic 	[lamda_len-1:0] 							lamda[0:2],
	input 														isWorking_deci,
	input   logic 	[5:0]										cnt,
	input 	logic 	signed [dist_len-1+num_category:0] 			dist_one_type,
	input   logic	[2:0]										best_bo_category,
	input   logic 	signed 	[dist_len-1+num_category:0] 		dist_bo_type_best,
	input	logic												isLeftMergeAvail,
	input	logic												isUpperMergeAvail,							
	input	logic			[$clog2(32)-1:0]					L_typeAuxInfo[0:2],	
	input	logic			[$clog2(32)-1:0]					U_typeAuxInfo[0:2], 
	input	logic			[n_sao_type-1:0]					L_merge_sao_type[0:1],
	input	logic			[n_sao_type-1:0]					U_merge_sao_type[0:1],
	input	logic	[4:0]										cand_bo[0:2],

	output 	logic	[2:0]										typeAuxInfo_3bit_ary[0:2],
	output 	logic 	[2:0]    									best_sao_type[0:1],
	output 	logic 	[1:0]    									sao_mode[0:1],					//0： OFF    1:NEW   2:MERGE
	output 	logic 	[eo_bo_type_len-1:0]   						best_typeAuxInfo[0:2]
);

logic 	[rate_len+lamda_len-1:0] 								r_l;

logic 	signed [dist_len+num_category+2:0]    					best_cost;
logic 	signed [dist_len+num_category+2:0]    					merge_cost[0:1];

logic 	signed [dist_len+num_category+2:0]    					cost_one_type_;
logic [rate_len-1:0] 											rate;
logic 	signed [dist_len+num_category+1:0]    					org_cost;

logic    		[dist_len+num_category+1:0]						MAX_COST;
logic			[lamda_len-1:0] 							    lamda_avg;
logic 	signed [dist_len+num_category:0]    					cost_L_best;
logic 	signed [dist_len+num_category+1:0]    					cost_C[0:n_total_type-1];
logic 	signed [dist_len+num_category:0] 						cost_one_type;
logic 															flag[0:2];
logic	[lamda_len+1:0]		SAO_OFF_R_L;


assign MAX_COST = (1<<(dist_len+num_category+2))-1;

always_comb begin
	rate = 3;
	if(isWorking_deci) begin
		if(cnt<49-SHIFT && !cIdx)
			rate = 10;
		if(cnt<49-SHIFT && cIdx==1)
			rate = 16;
		if(cnt>48-SHIFT)
			rate = 1;
		if(cIdx==2)
			rate = 0;
	end
end

assign r_l = rate*lamda[cIdx];

logic signed [dist_len+num_category+2:0]      merge_cost_final;


always_comb begin
	org_cost = 0;
	cost_one_type = 0;
	if(cIdx) begin
		case(cnt)
		6'd4: 	org_cost = cost_C[0]; 
		6'd8: 	org_cost = cost_C[1]; 
		6'd12: 	org_cost = cost_C[2]; 
		6'd16:	org_cost = cost_C[3]; 
		6'd24:	org_cost = cost_C[4]; 
		6'd28:  org_cost = merge_cost[0];
		6'd32:  org_cost = merge_cost[1];
		/*
		6'd48:	org_cost = cost_C[4]; 
		6'd52:  org_cost = merge_cost[0];
		6'd56:  org_cost = merge_cost[1];
		*/
		default: begin 	end
		endcase
	end
	if(cnt<17)
		cost_one_type = dist_one_type+$signed({1'b0,r_l});
	else if(cnt == 48-SHIFT)
		cost_one_type = dist_bo_type_best+$signed({1'b0,r_l});
	else if(cnt>48-SHIFT)
		cost_one_type = dist_one_type;
	
	
	
	cost_one_type_ = cost_one_type + org_cost;			//for accumulate the cb and cr. 
	
	lamda_avg = (lamda[0] + lamda[1] +1)>>1;
	
	SAO_OFF_R_L = (lamda[cIdx]<<1) + lamda[cIdx];
end
/*
generate 
	for(genvar cIdx=0; cIdx<3; cIdx++) begin:loop_flag
		always_comb begin
			flag[cIdx] = 1;
			if(cnt==28  && (L_typeAuxInfo[cIdx] < cand_bo[cIdx]-3 || L_typeAuxInfo[cIdx]> cand_bo[cIdx]+1) && L_merge_sao_type[|cIdx] == 4)
				flag[cIdx] = 0;
			if(cnt==32  && (U_typeAuxInfo[cIdx] < cand_bo[cIdx]-3 || U_typeAuxInfo[cIdx]> cand_bo[cIdx]+1) && U_merge_sao_type[|cIdx] == 4)
				flag[cIdx] = 0;
		end
	end
endgenerate
*/
always_comb	begin
			flag[0] = 1;
			if(cnt==28  && (L_typeAuxInfo[0] < cand_bo[0]-3 || L_typeAuxInfo[0]> cand_bo[0]+1) && L_merge_sao_type[0] == 4)
				flag[0] = 0;
			if(cnt==32  && (U_typeAuxInfo[0] < cand_bo[0]-3 || U_typeAuxInfo[0]> cand_bo[0]+1) && U_merge_sao_type[0] == 4)
				flag[0] = 0;
			flag[1] = 1;
			if(cnt==28  && (L_typeAuxInfo[1] < cand_bo[1]-3 || L_typeAuxInfo[1]> cand_bo[1]+1) && L_merge_sao_type[1] == 4)
				flag[1] = 0;
			if(cnt==32  && (U_typeAuxInfo[1] < cand_bo[1]-3 || U_typeAuxInfo[1]> cand_bo[1]+1) && U_merge_sao_type[1] == 4)
				flag[1] = 0;
			flag[2] = 1;
			if(cnt==28  && (L_typeAuxInfo[2] < cand_bo[2]-3 || L_typeAuxInfo[2]> cand_bo[2]+1) && L_merge_sao_type[1] == 4)
				flag[2] = 0;
			if(cnt==32  && (U_typeAuxInfo[2] < cand_bo[2]-3 || U_typeAuxInfo[2]> cand_bo[2]+1) && U_merge_sao_type[1] == 4)
				flag[2] = 0;
end

always_ff @(posedge clk or negedge arst_n)
	if(!arst_n)begin
		cost_L_best <= 0;
		cost_C[0] <= 0;
		cost_C[1] <= 0;
		cost_C[2] <= 0;
		cost_C[3] <= 0;
		cost_C[4] <= 0;
		{best_sao_type[0],best_sao_type[1]}<=0;
		{best_typeAuxInfo[1],best_typeAuxInfo[0],best_typeAuxInfo[2]}<=0;
		{typeAuxInfo_3bit_ary[1],typeAuxInfo_3bit_ary[0],typeAuxInfo_3bit_ary[2]}<=0;
		best_cost <= {1'b0,{27{1'b1}}};
		{sao_mode[0],sao_mode[1], merge_cost[0], merge_cost[1],merge_cost_final} <= 0;

		
	end 
	else if(!rst_n) begin
		cost_L_best <= 0;
		cost_C[0] <= 0;
		cost_C[1] <= 0;
		cost_C[2] <= 0;
		cost_C[3] <= 0;
		cost_C[4] <= 0;
		{best_sao_type[0],best_sao_type[1]}<=0;
		{best_typeAuxInfo[1],best_typeAuxInfo[0],best_typeAuxInfo[2]}<=0;
		{typeAuxInfo_3bit_ary[1],typeAuxInfo_3bit_ary[0],typeAuxInfo_3bit_ary[2]}<=0;
		best_cost <= 0;
		{sao_mode[0],sao_mode[1], merge_cost[0], merge_cost[1],merge_cost_final} <= 0;

	end
	else begin
		if(en_o) begin
			case(cnt)
				6'd3:  begin
					if(!cIdx) cost_L_best<= SAO_OFF_R_L;
				end
				6'd4: 	begin
					if(!cIdx) begin
						if(cost_one_type <cost_L_best) begin
							cost_L_best<= cost_one_type;  
							sao_mode[0] <= 1;
							best_sao_type[0] <= 0;
						end
					end
					else cost_C[0]<= cost_one_type_;  
					end
				6'd8: 		begin
					if(!cIdx) begin
						if(cost_one_type <cost_L_best) begin
							cost_L_best<= cost_one_type;  
							sao_mode[0] <= 1;
							best_sao_type[0] <= 1;
							
							end
					end
					else cost_C[1]<= cost_one_type_;  
					end
				6'd12: 		begin
					if(!cIdx)  begin
						if(cost_one_type <cost_L_best) begin
							cost_L_best<= cost_one_type;  
							sao_mode[0] <= 1;
							best_sao_type[0] <= 2;
						end
					end
					else cost_C[2]<= cost_one_type_;  
					end
				6'd16:		begin
					if(!cIdx)  begin
						if(cost_one_type <cost_L_best) begin
							cost_L_best<= cost_one_type;  
							sao_mode[0] <= 1;
							best_sao_type[0] <= 3;
						end
					end
					else cost_C[3]<= cost_one_type_;  
					end
				//6'd48:		begin
				6'd24:		begin
					if(!cIdx)  begin
						if(cost_one_type <cost_L_best) begin
							cost_L_best<= cost_one_type;  
							sao_mode[0] <= 1;
							best_sao_type[0] <= 4;
							typeAuxInfo_3bit_ary[0] <= best_bo_category;
							best_typeAuxInfo[0] <= best_bo_category+cand_bo[0]-3;
						end
					end
					else begin 
						cost_C[4]<= cost_one_type_;  
						if(cIdx[1]==0) begin		//cIdx==1
							typeAuxInfo_3bit_ary[1] <= best_bo_category;
							best_typeAuxInfo[1] <= best_bo_category+cand_bo[1]-3;
							end
						end
					end
			//	6'd52:	begin
				6'd28: begin
					if(isLeftMergeAvail) begin
						if(!cIdx[1])
							merge_cost[0]<=cost_one_type_;
						else 
							merge_cost[0]<=0;		//refresh
						if(cost_one_type_ < merge_cost_final && cIdx[1] && flag[0] && flag[1] && flag[2]) begin
							sao_mode[0] <= 2;
							best_sao_type[0] <= 0;
							best_typeAuxInfo[0] <= L_typeAuxInfo[0];	
							best_typeAuxInfo[1] <= L_typeAuxInfo[1];
						end
					end
				end
				//6'd56:	begin
				6'd32:	begin
					if(isUpperMergeAvail) begin
						if(!cIdx[1])
							merge_cost[1]<=cost_one_type_;
						else
							merge_cost[1]<=0;
						
						if(cost_one_type_ < merge_cost_final && cIdx[1] && flag[0] && flag[1] && flag[2])	begin
							sao_mode[0] <= 2;				//output
							best_sao_type[0] <= 1;			//output
							best_typeAuxInfo[0] <= U_typeAuxInfo[0];	
							best_typeAuxInfo[1] <= U_typeAuxInfo[1];	
						end
					end
				end
			default: begin  end
			endcase
			
			if(cIdx[1] ) begin		//cIdx ==2
				case(cnt)
				6'd3:   begin
						best_cost <= SAO_OFF_R_L;
				end
				6'd4: 	begin
							if(cost_one_type_ < best_cost) begin
								sao_mode[1] <= 1;
								best_cost <= cost_one_type_;
								best_sao_type[1] <= 0;

							end
						end
				6'd8: 	begin 
							if(cost_one_type_ < best_cost) begin
								sao_mode[1] <= 1;
								best_cost <= cost_one_type_;
								best_sao_type[1] <= 1;
							end
						end
				6'd12: begin 
							if(cost_one_type_ < best_cost) begin
								sao_mode[1] <= 1;
								best_cost <= cost_one_type_;
								best_sao_type[1] <= 2;
							end
						end
				6'd16:	begin 
							if(cost_one_type_ < best_cost) begin
								sao_mode[1] <= 1;
								best_cost <= cost_one_type_;
								best_sao_type[1] <= 3;
							end
						end
				//6'd48:	begin 
				6'd24:	begin 
							if(cost_one_type_ < best_cost) begin
								sao_mode[1] <= 1;				// NEW
								best_cost <= cost_one_type_;
								best_sao_type[1] <= 4;
								typeAuxInfo_3bit_ary[2]  <= best_bo_category;
								best_typeAuxInfo[2]  <= best_bo_category+cand_bo[2]-3;
							end
						end
			//	6'd51: begin
				6'd27: begin
					merge_cost_final <= best_cost+cost_L_best - $signed({1'b0,lamda_avg});	
				end
				//6'd52:  begin
				6'd28:  begin
							if(cost_one_type_ < merge_cost_final && isLeftMergeAvail && flag[0] && flag[1] && flag[2]) begin
								sao_mode[1] <= 2;				// MERGE
								merge_cost_final <= cost_one_type_;
								best_sao_type[1] <= 0;
								best_typeAuxInfo[2] <= L_typeAuxInfo[2];
								
							end
						end
				//6'd56:  begin
				6'd32:  begin
						cost_L_best<=0;
						cost_C[0]<=0;
						cost_C[1]<=0;
						cost_C[2]<=0;
						cost_C[3]<=0;
						cost_C[4]<=0;
							if(cost_one_type_ < merge_cost_final && isUpperMergeAvail && flag[0] && flag[1] && flag[2]) begin
								sao_mode[1] <= 2;				// MERGE	//output+mem
								merge_cost_final <= cost_one_type_;
								best_sao_type[1] <= 1;				//output
								best_typeAuxInfo[2] <= U_typeAuxInfo[2];	//output+mem
							end
						end
			//	6'd59:	begin
				6'd35:	begin
							{sao_mode[0],sao_mode[1]} <= 0;
							best_cost <= {1'b0,{27{1'b1}}};
							{best_sao_type[0],best_sao_type[1]} <=0;
							{best_typeAuxInfo[0],best_typeAuxInfo[1],best_typeAuxInfo[2]} <=0;
				
						end
				default: begin   end
				endcase
			end
			
		end
	end

endmodule