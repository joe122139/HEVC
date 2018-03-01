module sao_stat_bo_reduce #(
parameter bit_depth = 8,
parameter n_pix = 4
)
(
	
	input	logic									clk,rst_n,arst_n,wait_forPre,en_o,
	input	logic									not_end_pre_stage,
	input	logic 	[1:0]							cIdx,
	input	logic 	[bit_depth-1:0] 				n_rec_m[0:n_pix-1],
	input	logic									is_bo_pre,
	input	logic									isWorking_stat,
	
	output 	logic	[4:0]    						cand_bo[0:2]

);

logic	[bit_depth:0]				a,b;
logic	[bit_depth:0]				c,d;
logic	[bit_depth-1:0]				avg_22;
logic	[bit_depth+4:0]				sum;
logic	[bit_depth+4:0]				sum_16;
logic	[bit_depth+4:0]				sum_8;
logic								isWorking_stat_r1;
logic								isCollect,isAccu;
logic								isCollect_,isAccu_;

	always_comb begin
	//	a = n_rec_m[0]+n_rec_m[1];
	//	b = n_rec_m[2]+n_rec_m[3];
//		avg_22 = (a + b + 2 )>>2;
		sum_16 = sum+16;
		sum_8 = sum+8;
	end
	
	
	always_ff @(posedge clk or negedge arst_n)
		if(!arst_n) begin
			{cand_bo[0],cand_bo[1],cand_bo[2],sum,avg_22,isWorking_stat_r1,isCollect,isAccu} <= 0;
			{a,b}<=0;
			`ifdef PIX_8
			{c,d}<=0;
			`endif
			{isCollect_,isAccu_}<=0;
		end
		else if (!rst_n) begin
			{cand_bo[0],cand_bo[1],cand_bo[2],sum,avg_22,isWorking_stat_r1,isCollect,isAccu} <= 0;
			{a,b}<=0;
			`ifdef PIX_8
			{c,d}<=0;
			`endif
			{isCollect_,isAccu_}<=0;
		end
		else begin
			if(en_o)	begin
				isCollect_ <= isWorking_stat && !not_end_pre_stage;
				isAccu_ <= isWorking_stat && is_bo_pre;
				{isCollect,isAccu}<={isCollect_,isAccu_};
				a <= n_rec_m[0]+n_rec_m[1];
				b <= n_rec_m[2]+n_rec_m[3];
				`ifdef PIX_8
				c <= n_rec_m[4]+n_rec_m[5];
				d <= n_rec_m[6]+n_rec_m[7];
				avg_22 <= (a+b +c + d + 4 )>>3;
				`else
				avg_22 <= (a + b + 2 )>>2;
				`endif
				//if(isWorking_stat && !not_end_pre_stage) begin		//at the end of 
				if(isAccu)
					sum <= avg_22 + sum;
				else if(isCollect) begin
					sum <= 0;
					if(!cIdx)	begin
						cand_bo[0] <= sum_16>>8;		
					end
					else if(cIdx==1) begin
						cand_bo[1] <= sum_8>>7;
						end
					else begin
						cand_bo[2] <= sum_8>>7;
						end
				end
				//else if(wait_forPre && isWorking_stat && is_bo_pre)
//				else 
			end
		
		end

endmodule