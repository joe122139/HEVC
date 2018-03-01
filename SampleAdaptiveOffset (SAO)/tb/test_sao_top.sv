`ifndef FODIR
`define FODIR "../sim/data_file/"
`endif
`timescale 1ns/1ps
parameter luma_wait_cycle = 32;
parameter chroma_wait_cycle = 30;
parameter SHIFT = 24;
parameter n_eo_type = 4;
parameter bit_depth = 8;
parameter diff_clip_bit = 4;
`ifdef PIX_8
parameter n_pix = 8;
`else
parameter n_pix = 4;
`endif
parameter org_window_width = 4;
parameter org_window_height = n_pix/org_window_width;
parameter pic_width_len = 13;
parameter pic_height_len = 13;
parameter blk_22_X_len = 6;
parameter blk_22_Y_len = 6;
parameter cnt_st_len = 10;
parameter cnt_dc_len = 6;
parameter isChroma  = 0;
parameter cut_x_len = 9;
parameter cut_y_len = 9;
parameter num_pix_CTU_log2 = 5;
parameter num_accu_len = num_pix_CTU_log2*2;
parameter n_category = 4;
parameter n_category_bo = 8;
parameter sao_type_len = 3;
parameter offset_len = 4;

program automatic  tb_stat(
	input logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU[0:n_eo_type-1][0:n_category-1],
	input logic 	[num_accu_len:0]										num_blk_CTU[0:n_eo_type-1][0:n_category-1],

	input logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU_bo[0:n_category_bo-1],
	input logic 	[num_accu_len:0]										num_blk_CTU_bo[0:n_category_bo-1],
	input logic clk,
	
	output logic	[blk_22_X_len-1:0]					X_,
	output logic	[blk_22_X_len-1:0]					Y_,
	output	logic 	[cut_x_len-1:0]						ctu_x,
	output	logic 	[cut_y_len-1:0]						ctu_y,
	output 	logic 	[bit_depth-1:0] 				n_org_m[0:n_pix-1],
	output  logic 	[bit_depth-1:0] 				rec_in[0:org_window_height+1][0:org_window_width+1]
);
	initial begin
		integer				fc,r,j,fq,fb,fq_,l;
	//	logic chroma_wait;
		logic isWorking_stat,wait_forPre;
		integer             x,y,cnt_st;
		integer				cIdx;
		integer				t_sum,t_num,commas;
		
		fc = $fopen({`FODIR,"sao_input",".txt"},"r");
		fq = $fopen({`FODIR,"HO_SAO_SUM",".txt"},"w");
		fb = $fopen({`FODIR,"sao_input_cand_BO",".txt"},"r");
		
		fq_ = $fopen({`FODIR,"sao_sum",".txt"},"r");
	//	assign chroma_wait = sao_top.sao_FSM.chroma_wait;
		assign isWorking_stat = sao_top_clk.sao_top.isWorking_stat;
		assign wait_forPre = sao_top_clk.sao_top.wait_forPre;
		assign cnt_st = sao_top_clk.sao_top.cnt_st;
		assign cIdx = sao_top_clk.sao_top.cIdx;
		
		
		
		forever @(posedge clk) begin
		
	//		ctu_x = 0;
	//		ctu_y = 0;
			for(integer i = 0; i < org_window_height+2; i = i + 1)	begin
					for(j = 0; j < org_window_width+2; j = j + 1) begin
						rec_in[i][j] = 0;
				end
			end
			for(integer i = 0; i < n_pix; i = i + 1)	begin
					n_org_m[i] = 0;
			end
			X_ = 0;
			Y_ = 0;
			
			if(!test_sao_top.chroma_w && isWorking_stat)	begin
				r = $fscanf(fc,"%d",x);
				ctu_x = x / 16;
				
				r = $fscanf(fc,"%d",y);
				ctu_y = y / 16;
				r = $fscanf(fc,"%d",X_);
				r = $fscanf(fc,"%d",Y_);
			
				assert(X_ == sao_top_clk.sao_top.X);
				assert(Y_ == sao_top_clk.sao_top.Y);
				
		//		if(X_ != sao_top_clk.sao_top.X || Y_ != sao_top_clk.sao_top.Y) 
		//			$stop;
					
				for(integer i = 0; i < n_pix; i = i + 1)
					r = $fscanf(fc,"%d",n_org_m[i]);
				
				for(integer i = 0; i < org_window_height+2; i = i + 1)	begin
					for(j = 0; j < org_window_width+2; j = j + 1) 
						r = $fscanf(fc,"%d",rec_in[i][j]);
				end
			end

			if(wait_forPre && ((cIdx==0 && cnt_st <32) ||(cIdx && cnt_st<16)) && isWorking_stat) begin	//pre
				for(integer i = 1; i < org_window_height+1; i = i + 1)
					for(j = 1; j < org_window_width+1; j = j + 1) 
						r = $fscanf(fb,"%d",rec_in[i][j]);
			end
			
			if(!test_sao_top.chroma_w_r4 && test_sao_top.isWorking_stat_r4) begin
				for(integer k=0;k<n_eo_type;k++) begin				
					for(integer i = 0; i < 4; i = i + 1)		begin	
						$fwrite(fq,"%d %d   ",sum_blk_CTU[k][i],num_blk_CTU[k][i]);
						r = $fscanf(fq_,"%d",t_sum);
	
						r = $fscanf(fq_,"%d",t_num);
						if(t_sum !== sum_blk_CTU[k][i] || t_num !== num_blk_CTU[k][i]) begin
							$write("\n\nAt time %d DBGR: FO/HO mismatch detected in SC: ", $time); 
							$write("[%0d][%0d]\n",i,j);
							$write(" HO: %d %d !=  ",sum_blk_CTU[k][i],num_blk_CTU[k][i]);
							$write(" FO: %d %d \n\n",t_sum,t_num);
					//		$stop;
						end
					end
					$fwrite(fq,"\t");
				end
				
				for(integer k=0;k<n_category_bo;k++) begin				
					$fwrite(fq,"%d %d   ",sum_blk_CTU_bo[k],num_blk_CTU_bo[k]);
					r = $fscanf(fq_,"%d",t_sum);
					r = $fscanf(fq_,"%d",t_num);
					if(t_sum !== sum_blk_CTU_bo[k] || t_num !== num_blk_CTU_bo[k]) begin
							$write("\n\nAt time %d DBGR: FO/HO mismatch detected in SC: ", $time); 
							$write("BO[%0d]\n",k);
							$write(" HO: %d %d !=  ",sum_blk_CTU_bo[k],num_blk_CTU_bo[k]);
							$write(" FO: %d %d \n\n",t_sum,t_num);
					//		$stop;
						end
					end
			r = $fscanf(fq_,"%s",commas);	
			r = $fscanf(fq_,"%s",commas);					
				$fwrite(fq,"//X==%d Y==%d\n",test_sao_top.X_3,test_sao_top.Y_3);
				
				if(sao_top_clk.sao_top.cnt_st==2)
					$display("%d \n",sao_top_clk.sao_top.cIdx);
			end
		end
	end

endprogram:tb_stat

program automatic tb_deci(
	output logic   [8:0]								lamda[0:2],
	input logic clk);
	initial begin
		integer				c,p,re,me,cost_f;
		integer 			cnt;
		integer				dis,r_l,cost;
		integer				bo_cate;
		integer 			CTU_cnt;
		integer 			re_val[9];
		integer				flag;

		CTU_cnt = 0;
		p = $fopen({`FODIR,"HO_SAO_NSO",".txt"},"w");
		c = $fopen({`FODIR,"SAO_GP",".txt"},"r");
		me = $fopen({`FODIR,"HO_sao_output_cost",".txt"},"w");
		cost_f =  $fopen({`FODIR,"sao_output_cost",".txt"},"r");
		
		re = $fscanf(c,"%d",lamda[0]);
		re = $fscanf(c,"%d",lamda[1]);
		re = $fscanf(c,"%d",lamda[2]);
		flag = 1;
		
		forever @(posedge clk) begin
		//	dis = sao_top.sao_deci_top.sao_deci_cost.dist_one_type;
		//	r_l = sao_top.sao_deci_top.sao_deci_cost.r_l;
		//	cost = sao_top.sao_deci_top.sao_deci_cost.cost_one_type;
		//	bo_cate = sao_top.sao_deci_top.sao_deci_dist_accu_shift.bo_cate;
			cnt = sao_top_clk.sao_top.cnt_dc;
			
			if(sao_top_clk.sao_top.cIdx_dc==2) begin
				if(cnt== 58-SHIFT || cnt== 59-SHIFT) begin
					flag = 1;
					for (integer i=0;i<7; i++) begin
						if(i>2) 
							re = $fscanf(cost_f,"%d",re_val[i+2]);
						else 
							re = $fscanf(cost_f,"%d",re_val[i]);
						$display("%d",re_val[i]);
						
					end
				end
				else if(cnt==57-SHIFT) begin
					flag =0;
					for (integer i=0;i<9; i++) begin
						if (i!=3) re = $fscanf(cost_f,"%d",re_val[i]);
						else re = $fscanf(cost_f,"%s",re_val[i]);
						$display("%d",re_val[i]);
					end
				end
				
				if(cnt==57-SHIFT)	begin
					$fwrite(me,"%d %d %d 		CTU\t%d\n",test_sao_top.sao_mode[0],test_sao_top.sao_type[0],test_sao_top.typeAuxInfo[0],CTU_cnt);
					$fwrite(me,"%d %d %d %d\n",test_sao_top.offset[0],test_sao_top.offset[1],test_sao_top.offset[2],test_sao_top.offset[3]);
					
					
					if(test_sao_top.sao_mode[0]==re_val[0])	begin
						if(re_val[0]==0)
							flag = 1;
						else if(re_val[0]==1)
						begin
							if(  test_sao_top.sao_type[0]==re_val[1]   &&    (re_val[1]!=4 ||  ( re_val[2]== test_sao_top.typeAuxInfo[0]) ) ) 
							begin
								if(re_val[5]==test_sao_top.offset[0] && re_val[6]==test_sao_top.offset[1] && re_val[7]==test_sao_top.offset[2] && re_val[8]==test_sao_top.offset[3])
									flag = 1;
								else
									flag = 0;		//offset !=
							end
							else 
								flag = 0;	// type !=
						end
						else if (re_val[0]==2)	begin
							if(re_val[1] == test_sao_top.sao_type[0])
								flag = 1;
							else 
								flag = 0;
						end
					end
					else 
						flag = 0;	//mode !=
					
					
					
				end
				else if(cnt==58-SHIFT)	begin
					$fwrite(me,"%d %d %d\n",test_sao_top.sao_mode[1],test_sao_top.sao_type[1],test_sao_top.typeAuxInfo[1]);
					$fwrite(me,"%d %d %d %d\n",test_sao_top.offset[0],test_sao_top.offset[1],test_sao_top.offset[2],test_sao_top.offset[3]);
					if(test_sao_top.sao_mode[1]==re_val[0])	begin
						if(re_val[0]==0)
							flag = 1;
						else if(re_val[0]==1)
						begin
							if(  test_sao_top.sao_type[1]==re_val[1]   &&    (re_val[1]!=4 ||  ( re_val[2]== test_sao_top.typeAuxInfo[1]) ) ) 
							begin
								if(re_val[5]==test_sao_top.offset[0] && re_val[6]==test_sao_top.offset[1] && re_val[7]==test_sao_top.offset[2] && re_val[8]==test_sao_top.offset[3])
									flag = 1;
								else
									flag = 0;		//offset !=
							end
							else 
								flag = 0;	// type !=
						end
					/*	else if (re_val[0]==2)	begin
							if(re_val[1] == test_sao_top.sao_type[0])
								flag = 1;
							else 
								flag = 0;
						end*/
					end
					else 
						flag = 0;	//mode !=
				end
				else if(cnt==59-SHIFT)	begin
					$fwrite(me,"%d %d %d\n",test_sao_top.sao_mode[1],test_sao_top.sao_type[1],test_sao_top.typeAuxInfo[2]);
					$fwrite(me,"%d %d %d %d\n\n",test_sao_top.offset[0],test_sao_top.offset[1],test_sao_top.offset[2],test_sao_top.offset[3]);
					if(test_sao_top.sao_mode[1]==re_val[0])	begin
						if(re_val[0]==0)
							flag = 1;
						else if(re_val[0]==1)
						begin
							if(  test_sao_top.sao_type[1]==re_val[1]   &&    (re_val[1]!=4 ||  ( re_val[2]== test_sao_top.typeAuxInfo[2]) ) ) 
							begin
								if(re_val[5]==test_sao_top.offset[0] && re_val[6]==test_sao_top.offset[1] && re_val[7]==test_sao_top.offset[2] && re_val[8]==test_sao_top.offset[3])
									flag = 1;
								else
									flag = 0;		//offset !=
							end
							else 
								flag = 0;	// type !=
						end
					/*	else if (re_val[0]==2)	begin
							if(re_val[1] == test_sao_top.sao_type[0])
								flag = 1;
							else 
								flag = 0;
						end*/
					end
					else 
						flag = 0;	//mode !=
					
					
					CTU_cnt++;
				end
				
				
				
				
			end
			
			if (flag == 0) begin 
				$write("\n\nAt time %d DBGR: FO/HO mismatch detected in PD: %d %d %d %d %d %d %d %d %d ", $time, re_val[0],re_val[1],re_val[2],re_val[3],re_val[4],re_val[5],re_val[6],re_val[7],re_val[8]); 
				$stop; 
			end
			
			
			
		end
	end
endprogram:tb_deci


module test_sao_top();
parameter           CK = 10.0;

logic 		clk,arst_n,rst_n,clk_slow;
logic [5:0] X,Y,X_1,X_2,Y_1,Y_2,X_3,Y_3;

logic   chroma_w;
logic   chroma_w_r1,chroma_w_r2,chroma_w_r3,chroma_w_r4;
logic isWorking_stat_r1,isWorking_stat_r2,isWorking_stat_r3,isWorking_stat_r4;
logic  cIdx;



logic 			[sao_type_len-1:0]										sao_type[0:1];
logic 	signed	[offset_len-1:0]										offset[0:n_category-1];
logic 			[1:0]    												sao_mode[0:1];					//0： OFF    1:NEW   2:MERGE
logic 			[$clog2(32)-1:0]   										typeAuxInfo[0:2];
	
logic 	[pic_width_len-1:0]												pic_width;			
logic 	[pic_height_len-1:0]											pic_height;



logic	[blk_22_X_len-1:0]					X_;
logic	[blk_22_X_len-1:0]					Y_;
logic 										en_i,en_o,en_o_2;

logic 	[cut_x_len-1:0]						ctu_x;
logic 	[cut_y_len-1:0]						ctu_y;
logic   [2:0]								ctb_size_log2;
logic 	[bit_depth-1:0] 					n_org_m[0:n_pix-1];	
logic 	[bit_depth-1:0] 					rec_in[0:org_window_height+1][0:org_window_width+1];
logic	[2:0]								ctu_size;
logic   [8:0]								lamda[0:2];

logic   [1:0]								cIdx_dc,cIdx_st;
logic	[5:0]								cnt_dc;
logic	[9:0]								cnt_st;
logic										wait_forPre;

logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU[0:n_eo_type-1][0:n_category-1];
logic 	[num_accu_len:0]										num_blk_CTU[0:n_eo_type-1][0:n_category-1];

logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU_bo[0:n_category_bo-1];
logic 	[num_accu_len:0]										num_blk_CTU_bo[0:n_category_bo-1];

assign cIdx =  sao_top_clk.sao_top.cIdx;

assign 	chroma_w = sao_top_clk.sao_top.wait_forPre;
assign isWorking_stat_r1 = sao_top_clk.sao_top.isWorking_stat_r1;


initial begin
  clk = 0; 
  #(CK/2.0) 
  forever begin 
	#(CK/2.0) clk = ~clk;
  end
end
/*
initial begin
  clk_slow = 0; 
  #(CK/2.0) 
  forever begin 
	#(CK*3) clk_slow = ~clk_slow;
  end
end
*/



initial begin
	arst_n = 0;
	rst_n =0;
	en_i = 1;
	en_o = 1;
	en_o_2 = 1;
	pic_width = 13'd416;
	pic_height = 13'd240;
	ctb_size_log2 = 6;
	ctu_size= 6;
	
	
	#CK arst_n = 1;
	#CK rst_n = 1;
	
end

always_ff @(posedge clk) begin
	{X} <= {sao_top_clk.sao_top.X};
	{Y}	<= {sao_top_clk.sao_top.Y};
	{X_1,Y_1} <= {X,Y};
	{X_2,Y_2} <= {X_1,Y_1};
	{X_3,Y_3} <= {X_2,Y_2};
	chroma_w_r1 <= chroma_w;
	chroma_w_r2 <= chroma_w_r1;
	chroma_w_r3 <= chroma_w_r2;
	chroma_w_r4 <= chroma_w_r3;
	isWorking_stat_r2 <= isWorking_stat_r1;
	isWorking_stat_r3 <= isWorking_stat_r2;
	isWorking_stat_r4 <= isWorking_stat_r3;
	
end





tb_stat tb_stat(
	.clk,
	.sum_blk_CTU,
	.num_blk_CTU,

	.sum_blk_CTU_bo,
	.num_blk_CTU_bo,
	.*
);

tb_deci tb_deci(
	.lamda,
	.clk(sao_top_clk.sao_top.clk_slow)
);

sao_top_clk #(.num_pix_CTU_log2(num_pix_CTU_log2),.num_accu_len(num_accu_len),.n_pix(n_pix),.org_window_width(org_window_width)) sao_top_clk(
	.clk,
	.arst_n,
	.rst_n,
	.sao_type,
	.sao_mode,
	.typeAuxInfo,
	.offset,
//	.X_(X_),
//	.Y_(Y_),
	.en_i,
	.en_o,
//	.en_o_2,
	.ctu_x,
	.ctu_y,
	.n_org_m,
	.rec_in,
	.ctu_size,
	.lamda,
	.sum_blk_CTU,
	.num_blk_CTU,
	.sum_blk_CTU_bo,
	.num_blk_CTU_bo,
	.wait_forPre,
	.cnt_st,
	.cnt_dc,
	.cIdx(cIdx_st),
	.cIdx_dc,
	.*
);

endmodule