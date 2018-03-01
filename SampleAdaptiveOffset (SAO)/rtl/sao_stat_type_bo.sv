`timescale 1ns/1ps
`ifndef P7_BO_REDUCED
`define P7_BO_REDUCED
`endif

module sao_stat_type_bo #(
parameter BO_TYPE = 0,
parameter bit_depth = 8, 
parameter diff_clip_bit = 4,
parameter n_pix = 4,
`ifdef P7_BO_REDUCED
parameter n_category = 8,
`else
`endif
parameter cnt_st_len = 10,
parameter num_pix_CTU_log2 = 5,
parameter n_bo_type = 5,
parameter num_accu_len = num_pix_CTU_log2*2-1
)(
	input	logic  									clk,
	input	logic  									clk_slow,
	input	logic  									arst_n,
	input	logic  									rst_n,
	input	logic    								en_i,
	input	logic    								en_o,

	input	logic 	[bit_depth-1:0] 				n_rec_m[0:n_pix-1],
	input 	logic signed 	[diff_clip_bit:0]		n_diff[0:n_pix-1],
	input 	logic									not_end,
	input	[n_pix-1:0]								b_use,			//this pix is avail. or not.
	input   logic 									wait_forPre,
	input	logic	[1:0]							cIdx,
	input	logic  			[n_bo_type-1:0]			cand_bo_[0:2],
	input	logic									isWorking_stat,
	input	logic									isToRefresh,
//	input	logic									is_to_pass_data,
	
	output	logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU[0:n_category-1],
	output 	logic 	[num_accu_len:0]		num_blk_CTU[0:n_category-1]
//	output	logic signed [num_pix_CTU_log2*2+diff_clip_bit:0]						sum_blk_CTU_DCI[0:n_category-1],
//	output 	logic 	[num_pix_CTU_log2*2:0]		num_blk_CTU_DCI[0:n_category-1]
);
	
logic 			[n_pix-1:0]							sel[0:n_category-1];			//large		4bit x 32
logic  			[n_bo_type-1:0]						bo_cate [0:n_pix-1];
logic  			[n_bo_type-1:0]						bo_cate_r1 [0:n_pix-1];
logic signed 	[diff_clip_bit+2:0]					s41;
logic signed 	[diff_clip_bit+2:0]					s31;
logic signed 	[diff_clip_bit+1:0]					s21;
logic signed 	[diff_clip_bit:0]					s11;
`ifdef PIX_8
logic signed 	[diff_clip_bit+3:0]					s51;
logic signed 	[diff_clip_bit+3:0]					s61;
logic signed 	[diff_clip_bit+3:0]					s71;
logic signed 	[diff_clip_bit+3:0]					s81;
`endif
logic	[n_pix-1:0]									b_use_r1;			//this pix is avail. or not.
`ifdef P7_BO_REDUCED

logic			[2:0]								delta[0:n_pix-1];
logic			[2:0]								delta_[0:n_pix-1];

logic  			[n_bo_type-1:0]			cand_bo;
logic			[0:n_pix-1]							isLess;
logic												isWithin[0:n_pix-1];
assign 			cand_bo = cand_bo_[cIdx];
//assign     		delta[0] =  cand_bo - bo_cate[0];
//assign     		delta[1] =  cand_bo - bo_cate[1];
//assign     		delta[2] =  cand_bo - bo_cate[2];
//assign     		delta[3] =  cand_bo - bo_cate[3];

//assign     		delta_[0] =  bo_cate[0] - cand_bo ;
//assign     		delta_[1] =  bo_cate[1] - cand_bo ;
//assign     		delta_[2] =  bo_cate[2] - cand_bo ;
//assign     		delta_[3] =  bo_cate[3] - cand_bo ;



`endif
logic 												wait_forPre_r1;
logic												not_end_r1;


generate
	for(genvar bo_category=0;bo_category<n_category;bo_category++) begin:loop_bo_category
		always_ff @(posedge clk or negedge arst_n)
			if(!arst_n) begin
				sel[bo_category] <= 0;
				
			end
			else if (!rst_n) begin
				sel[bo_category] <= 0;
			end
			else begin
			`ifdef P7_BO_REDUCED
				if(en_o) begin
								
				`ifdef PIX_8	
					if(isWithin[0])
						if(isLess[0])
							sel[bo_category][n_pix-1] <= {bo_category == 3-delta[0]} && b_use_r1[0];
						else
							sel[bo_category][n_pix-1] <= {bo_category == 3+delta_[0]} && b_use_r1[0];
					else
						sel[bo_category][n_pix-1] <= 0;
					if(isWithin[1])
						if(isLess[1])
							sel[bo_category][n_pix-2] <= {bo_category == 3-delta[1]} && b_use_r1[1];
						else
							sel[bo_category][n_pix-2] <= {bo_category == 3+delta_[1]} && b_use_r1[1];
					else
						sel[bo_category][n_pix-2] <= 0;		
					if(isWithin[2])
						if(isLess[2])
							sel[bo_category][n_pix-3] <= {bo_category == 3-delta[2]} && b_use_r1[2];
						else
							sel[bo_category][n_pix-3] <= {bo_category == 3+delta_[2]} && b_use_r1[2];
					else
						sel[bo_category][n_pix-3] <= 0;		
					if(isWithin[3])
						if(isLess[3])
							sel[bo_category][n_pix-4] <= {bo_category == 3-delta[3]} && b_use_r1[3];
						else
							sel[bo_category][n_pix-4] <= {bo_category == 3+delta_[3]} && b_use_r1[3];
					else
						sel[bo_category][n_pix-4] <= 0;

					if(isWithin[4])
						if(isLess[4])
							sel[bo_category][3] <= {bo_category == 3-delta[4]} && b_use_r1[4];
						else
							sel[bo_category][3] <= {bo_category == 3+delta_[4]} && b_use_r1[4];
					else
						sel[bo_category][3] <= 0;
					if(isWithin[5])
						if(isLess[5])
							sel[bo_category][2] <= {bo_category == 3-delta[5]} && b_use_r1[5];
						else
							sel[bo_category][2] <= {bo_category == 3+delta_[5]} && b_use_r1[5];
					else
						sel[bo_category][2] <= 0;		
					if(isWithin[6])
						if(isLess[6])
							sel[bo_category][1] <= {bo_category == 3-delta[6]} && b_use_r1[6];
						else
							sel[bo_category][1] <= {bo_category == 3+delta_[6]} && b_use_r1[6];
					else
						sel[bo_category][1] <= 0;		
					if(isWithin[7])
						if(isLess[7])
							sel[bo_category][0] <= {bo_category == 3-delta[7]} && b_use_r1[7];
						else
							sel[bo_category][0] <= {bo_category == 3+delta_[7]} && b_use_r1[7];
					else
						sel[bo_category][0] <= 0;

					`else 
						if(isWithin[0])
						if(isLess[0])
							sel[bo_category][3] <= {bo_category == 3-delta[0]} && b_use_r1[0];
						else
							sel[bo_category][3] <= {bo_category == 3+delta_[0]} && b_use_r1[0];
					else
						sel[bo_category][3] <= 0;
					if(isWithin[1])
						if(isLess[1])
							sel[bo_category][2] <= {bo_category == 3-delta[1]} && b_use_r1[1];
						else
							sel[bo_category][2] <= {bo_category == 3+delta_[1]} && b_use_r1[1];
					else
						sel[bo_category][2] <= 0;		
					if(isWithin[2])
						if(isLess[2])
							sel[bo_category][1] <= {bo_category == 3-delta[2]} && b_use_r1[2];
						else
							sel[bo_category][1] <= {bo_category == 3+delta_[2]} && b_use_r1[2];
					else
						sel[bo_category][1] <= 0;		
					if(isWithin[3])
						if(isLess[3])
							sel[bo_category][0] <= {bo_category == 3-delta[3]} && b_use_r1[3];
						else
							sel[bo_category][0] <= {bo_category == 3+delta_[3]} && b_use_r1[3];
					else
						sel[bo_category][0] <= 0;

						`endif
				end
			`else
				if(en_o)	begin
					`ifdef PIX_8
					sel[bo_category] <= 
					{(bo_category) == bo_cate_r1[0],(bo_category) == bo_cate_r1[1],(bo_category) == bo_cate_r1[2],(bo_category) == bo_cate_r1[3], (bo_category) == bo_cate_r1[4],(bo_category) == bo_cate_r1[5],(bo_category) == bo_cate_r1[6],(bo_category) == bo_cate_r1[7]} & {b_use_r1[0],b_use_r1[1],b_use_r1[2],b_use_r1[3],b_use_r1[4],b_use_r1[5],b_use_r1[6],b_use_r1[7]};
					`else
					sel[bo_category] <= 
					{(bo_category) == bo_cate_r1[0],(bo_category) == bo_cate_r1[1],(bo_category) == bo_cate_r1[2],(bo_category) == bo_cate_r1[3]} & {b_use_r1[0],b_use_r1[1],b_use_r1[2],b_use_r1[3]};
					`endif
			end
			`endif
		end
		
		sao_stat_accu #(.num_pix(n_pix),.num_pix_CTU_log2(num_pix_CTU_log2),.num_accu_len(num_accu_len)) sao_stat_accu(
		.clk_slow,
		.s41,
		.s31,
		.s21,
		.s11,
		.sel(sel[bo_category]),
		.sum_blk_CTU(sum_blk_CTU[bo_category]),
		.num_blk_CTU(num_blk_CTU[bo_category]),
//		.sum_blk_CTU_DCI(sum_blk_CTU_DCI[bo_category]),
//		.num_blk_CTU_DCI(num_blk_CTU_DCI[bo_category]),
		.clk,
		.not_end(not_end_r1),
		.wait_forPre(wait_forPre_r1),
		.isToRefresh,
		//.is_to_pass_data,
		.*
	);
	end
endgenerate


always_ff @(posedge clk or negedge arst_n)
	if(!arst_n) begin
		{bo_cate_r1[0],bo_cate_r1[1],bo_cate_r1[2],bo_cate_r1[3]} <=0;
		`ifdef PIX_8
		{bo_cate_r1[4],bo_cate_r1[5],bo_cate_r1[6],bo_cate_r1[7]} <=0;
		`endif
		b_use_r1 <= 0;
		{wait_forPre_r1,not_end_r1,isLess} <= 0;
		{delta[0],delta[1],delta[2],delta[3],delta_[0],delta_[1],delta_[2],delta_[3]} <=0;
		`ifdef PIX_8
		{delta[4],delta[5],delta[6],delta[7],delta_[4],delta_[5],delta_[6],delta_[7]} <=0;
		`endif
		{isWithin[0],isWithin[1],isWithin[2],isWithin[3]}<=0;
		`ifdef PIX_8
		{isWithin[4],isWithin[5],isWithin[6],isWithin[7]}<=0;
		`endif
	end
	else if (!rst_n) begin
		{bo_cate_r1[0],bo_cate_r1[1],bo_cate_r1[2],bo_cate_r1[3]} <=0;
		`ifdef PIX_8
		{bo_cate_r1[4],bo_cate_r1[5],bo_cate_r1[6],bo_cate_r1[7]} <=0;
		`endif
		b_use_r1 <= 0;
		{wait_forPre_r1,not_end_r1,isLess} <= 0;
		{delta[0],delta[1],delta[2],delta[3],delta_[0],delta_[1],delta_[2],delta_[3]} <=0;
		`ifdef PIX_8
		{delta[4],delta[5],delta[6],delta[7],delta_[4],delta_[5],delta_[6],delta_[7]} <=0;
		`endif
		{isWithin[0],isWithin[1],isWithin[2],isWithin[3]}<=0;
		`ifdef PIX_8
		{isWithin[4],isWithin[5],isWithin[6],isWithin[7]}<=0;
		`endif
	end
	else begin
		if(en_o)	begin
			{bo_cate_r1[0],bo_cate_r1[1],bo_cate_r1[2],bo_cate_r1[3]} <={bo_cate[0],bo_cate[1],bo_cate[2],bo_cate[3]};
			`ifdef PIX_8
			{bo_cate_r1[4],bo_cate_r1[5],bo_cate_r1[6],bo_cate_r1[7]} <={bo_cate[4],bo_cate[5],bo_cate[6],bo_cate[7]};
			`endif
			b_use_r1 <= b_use;
			not_end_r1<= not_end;
			wait_forPre_r1<= wait_forPre;
			delta[0] <=  cand_bo - bo_cate[0];
			delta[1] <=  cand_bo - bo_cate[1];
			delta[2] <=  cand_bo - bo_cate[2];
			delta[3] <=  cand_bo - bo_cate[3];

			delta_[0] <=  bo_cate[0] - cand_bo ;
			delta_[1] <=  bo_cate[1] - cand_bo ;
			delta_[2] <=  bo_cate[2] - cand_bo ;
			delta_[3] <=  bo_cate[3] - cand_bo ;
			`ifdef PIX_8
			delta[4] <=  cand_bo - bo_cate[4];
			delta[5] <=  cand_bo - bo_cate[5];
			delta[6] <=  cand_bo - bo_cate[6];
			delta[7] <=  cand_bo - bo_cate[7];

			delta_[4] <=  bo_cate[4] - cand_bo ;
			delta_[5] <=  bo_cate[5] - cand_bo ;
			delta_[6] <=  bo_cate[6] - cand_bo ;
			delta_[7] <=  bo_cate[7] - cand_bo ;

			`endif
			
			
			isWithin[0]<= (bo_cate[0]<=cand_bo+4 && bo_cate[0]>=cand_bo-3 );
			isWithin[1]<= (bo_cate[1]<=cand_bo+4 && bo_cate[1]>=cand_bo-3 );
			isWithin[2]<= (bo_cate[2]<=cand_bo+4 && bo_cate[2]>=cand_bo-3 );
			isWithin[3]<= (bo_cate[3]<=cand_bo+4 && bo_cate[3]>=cand_bo-3 );

		`ifdef PIX_8
			isWithin[4]<= (bo_cate[4]<=cand_bo+4 && bo_cate[4]>=cand_bo-3 );
			isWithin[5]<= (bo_cate[5]<=cand_bo+4 && bo_cate[5]>=cand_bo-3 );
			isWithin[6]<= (bo_cate[6]<=cand_bo+4 && bo_cate[6]>=cand_bo-3 );
			isWithin[7]<= (bo_cate[7]<=cand_bo+4 && bo_cate[7]>=cand_bo-3 );	
			isLess[4:7] <= {bo_cate[4]<=cand_bo,bo_cate[5]<=cand_bo,bo_cate[6]<=cand_bo,bo_cate[7]<=cand_bo};
		`endif
			isLess[0:3] <= {bo_cate[0]<=cand_bo,bo_cate[1]<=cand_bo,bo_cate[2]<=cand_bo,bo_cate[3]<=cand_bo};

		end
	
	end

sao_stat_n_pix_bo #(.n_pix(n_pix)) sao_stat_n_pix_bo(
	.n_rec_m,
	.bo_cate
);

sao_stat_n_pix_add #(.n_pix(n_pix) ,.n_bo_type(n_bo_type)) sao_stat_n_pix_add(
	.n_diff,
	.cate(bo_cate_r1),
	.b_use(b_use_r1),
	.isWorking_stat,
	.s41,
	.s31,
	.s21,
	.s11,
	.en(en_o),
	.*
	);
	/*
generate
	for(genvar i=0;i<n_category;i++) begin:loopi

		sao_stat_accu #(.num_pix(n_pix)) sao_stat_accu(
		.sA,
		.s31,
		.s21,
		.s11,
		.sel(sel[i]),
		.sum_blk_CTU(sum_blk_CTU[i]),
		.num_blk_CTU(num_blk_CTU[i]),
		.sum_blk_CTU_DCI(sum_blk_CTU_DCI[i]),
		.num_blk_CTU_DCI(num_blk_CTU_DCI[i]),
		.clk,
		.not_end,
		.wait_forPre,
		.*
	);
	end
endgenerate
	
	*/
endmodule
