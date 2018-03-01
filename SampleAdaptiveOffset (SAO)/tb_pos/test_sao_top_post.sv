`ifndef FODIR
`define FODIR "../sim_smic40/data_file/"
`endif
`timescale 100ps/1ps
parameter luma_wait_cycle = 32;
parameter chroma_wait_cycle = 30;
parameter SHIFT = 24;
parameter n_eo_type = 4;
parameter bit_depth = 8;
parameter diff_clip_bit = 4;
parameter n_pix = 4;
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
parameter n_category = 4;
parameter n_category_bo = 8;
parameter sao_type_len = 3;
parameter offset_len = 4;

program automatic  tb_stat(
//	input logic signed [num_pix_CTU_log2*2+diff_clip_bit:0]						sum_blk_CTU[0:n_eo_type-1][0:n_category-1],
//	input logic 	[num_pix_CTU_log2*2:0]										num_blk_CTU[0:n_eo_type-1][0:n_category-1],

//	input logic signed [num_pix_CTU_log2*2+diff_clip_bit:0]						sum_blk_CTU_bo[0:n_category_bo-1],
//	input logic 	[num_pix_CTU_log2*2:0]										num_blk_CTU_bo[0:n_category_bo-1],
	input logic signed [num_pix_CTU_log2*2+diff_clip_bit:0]						sum_blk_CTU[n_eo_type-1:0][n_category-1:0],
	input logic 	[num_pix_CTU_log2*2:0]										num_blk_CTU[n_eo_type-1:0][n_category-1:0],

	input logic signed [num_pix_CTU_log2*2+diff_clip_bit:0]						sum_blk_CTU_bo[n_category_bo-1:0],
	input logic 	[num_pix_CTU_log2*2:0]										num_blk_CTU_bo[n_category_bo-1:0],
	input logic clk,
	
	output logic	[blk_22_X_len-1:0]					X_,
	output logic	[blk_22_X_len-1:0]					Y_,
	output	logic 	[cut_x_len-1:0]						ctu_x,
	output	logic 	[cut_y_len-1:0]						ctu_y,
	//output 	logic 	[bit_depth-1:0] 				n_org_m[0:n_pix-1],
	output 	logic 	[bit_depth-1:0] 				n_org_m[n_pix-1:0],
	//output 	logic 	[bit_depth-1:0] 				rec_in[0:n_pix-1][0:n_pix-1]
	output 	logic 	[bit_depth-1:0] 				rec_in[n_pix-1:0][n_pix-1:0]
);
	initial begin
		integer				fc,r,j,fq,fb,fq_;
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
		assign isWorking_stat = sao_top_clk.sao_top_isWorking_stat;
		assign wait_forPre = sao_top_clk.wait_forPre;
		assign cnt_st = sao_top_clk.cnt_st;
		assign cIdx = sao_top_clk.cIdx;
		
		forever @(posedge clk) begin

		fork
			ctu_x = 0;
			ctu_y = 0;
			for(integer i = 0; i < 4; i = i + 1)	begin
					n_org_m[i] = 0;
					for(j = 0; j < 4; j = j + 1) 
						rec_in[i][j] = 0;
			end
			X_ = 0;
			Y_ = 0;
			
			#2 if(!test_sao_top_post.chroma_w && isWorking_stat)	begin
				r = $fscanf(fc,"%d",x);
				ctu_x = x / 16;
				
				r = $fscanf(fc,"%d",y);
				ctu_y = y / 16;
				r = $fscanf(fc,"%d",X_);
				r = $fscanf(fc,"%d",Y_);
			
		//		assert(X_ == sao_top.X);
		//		assert(Y_ == sao_top.Y);
				
		//		if(X_ != sao_top_clk.X || Y_ != sao_top_clk.Y) 
		//			$stop;
					
				for(integer i = 0; i < 4; i = i + 1)
					 r = $fscanf(fc,"%d",n_org_m[i]);
				
				for(integer i = 0; i < 4; i = i + 1)
					for(j = 0; j < 4; j = j + 1) 
						 r = $fscanf(fc,"%d",rec_in[i][j]);
			end

			#2 if(wait_forPre && ((cIdx==0 && cnt_st <32) ||(cIdx && cnt_st<16)) && isWorking_stat) begin
				for(integer i = 1; i < 3; i = i + 1)
					for(j = 1; j < 3; j = j + 1) 
						 r = $fscanf(fb,"%d",rec_in[i][j]);
			end
			
			#2 if(!test_sao_top_post.chroma_w_r4 && test_sao_top_post.isWorking_stat_r4) begin
				for(integer k=0;k<n_eo_type;k++) begin				
					for(integer i = 0; i < 4; i = i + 1)		begin	
						$fwrite(fq,"%d %d ",sum_blk_CTU[k][i],num_blk_CTU[k][i]);
						r = $fscanf(fq_,"%d",t_sum);
	
						r = $fscanf(fq_,"%d",t_num);
						if(t_sum !== sum_blk_CTU[k][i] || t_num !== num_blk_CTU[k][i]) begin
							$write("\n\nAt time %d DBGR: FO/HO mismatch detected in SC: ", $time); 
							$write("[%0d][%0d]\n",i,j);
							$write(" HO: %d %d !=  ",sum_blk_CTU[k][i],num_blk_CTU[k][i]);
							$write(" FO: %d %d \n\n",t_sum,t_num);
							$stop;
						end
					end
					$fwrite(fq,"\t");
				end
				
				for(integer k=0;k<n_category_bo;k++) begin				
					$fwrite(fq,"%d %d ",sum_blk_CTU_bo[k],num_blk_CTU_bo[k]);
					r = $fscanf(fq_,"%d",t_sum);
					r = $fscanf(fq_,"%d",t_num);
					if(t_sum !== sum_blk_CTU_bo[k] || t_num !== num_blk_CTU_bo[k]) begin
							$write("\n\nAt time %d DBGR: FO/HO mismatch detected in SC: ", $time); 
							$write("BO[%0d]\n",k);
							$write(" HO: %d %d !=  ",sum_blk_CTU_bo[k],num_blk_CTU_bo[k]);
							$write(" FO: %d %d \n\n",t_sum,t_num);
							$stop;
						end
				end
			r = $fscanf(fq_,"%s",commas);	
			r = $fscanf(fq_,"%s",commas);					
				//$fwrite(fq,"//X=%d Y=%d\n",sao_top.X,sao_top.Y);
		//		$fwrite(fq,"//X==%d Y==%d\n",test_sao_top_post.X_3,test_sao_top_post.Y_3);
				$fwrite(fq,"\n");
				if(sao_top_clk.cnt_st==2)
					$display("%d \n",sao_top_clk.cIdx);
			end
		join
		
		end
	end

endprogram:tb_stat

program automatic tb_deci(
	output logic   [8:0]								lamda[0:2],
	input logic clk);
	initial begin
		integer				c,p,re,me;
		integer 			cnt;
		integer				dis,r_l,cost;
		integer				bo_cate;
		integer 			CTU_cnt;

		CTU_cnt = 0;
		p = $fopen({`FODIR,"HO_SAO_NSO",".txt"},"w");
		c = $fopen({`FODIR,"SAO_GP",".txt"},"r");
		me = $fopen({`FODIR,"HO_sao_output_cost",".txt"},"w");
		
		re = $fscanf(c,"%d",lamda[0]);
		re = $fscanf(c,"%d",lamda[1]);
		re = $fscanf(c,"%d",lamda[2]);
		
		
		forever @(posedge clk) begin
		//	dis = sao_top.sao_deci_top.sao_deci_cost.dist_one_type;
		//	r_l = sao_top.sao_deci_top.sao_deci_cost.r_l;
		//	cost = sao_top.sao_deci_top.sao_deci_cost.cost_one_type;
		//	bo_cate = sao_top.sao_deci_top.sao_deci_dist_accu_shift.bo_cate;
			cnt = sao_top_clk.cnt_dc;
		//	if(sao_top.sao_FSM.isWorking_deci) begin
		/*		if(cnt<16)	begin
					$fwrite(p,"%d %d %d %d//n,s,o,d,t:%d\n",sao_top.sum_blk_CTU_DCI[cnt/4][cnt%4],sao_top.num_blk_CTU_DCI[cnt/4][cnt%4],sao_top.sao_deci_top.offset[cnt/4][cnt%4],dis,cnt);
					end
				else if(cnt <48)
					$fwrite(p,"%d %d %d %d//n,s,o,d,t:%d\n",sao_top.sum_blk_CTU_bo_DCI[cnt-16],sao_top.num_blk_CTU_bo_DCI[cnt-16],sao_top.sao_deci_top.offset_bo[cnt-16],dis,cnt);
		*/			
		//		if(cnt<20 && cnt>3 && cnt%4==0)	
		//			$fwrite(p,"%d %d %d %d\n",dis, r_l,cost,cnt);
		//		if(cnt>19 && cnt <50-SHIFT)	
		//			$fwrite(p,"%d %d %d %d\n",dis, r_l,cost,bo_cate);	
		//		$fwrite(p,"\n");
	//		end
			if(sao_top_clk.cIdx_dc==2) begin
				if(cnt==57-SHIFT)	begin
					$fwrite(me,"%d %d %d 		CTU %d\n",test_sao_top_post.sao_mode[0],test_sao_top_post.sao_type[0],test_sao_top_post.typeAuxInfo[0],CTU_cnt);
					$fwrite(me,"%d %d %d %d\n",test_sao_top_post.offset[0],test_sao_top_post.offset[1],test_sao_top_post.offset[2],test_sao_top_post.offset[3]);
				end
				else if(cnt==58-SHIFT)	begin
					$fwrite(me,"%d %d %d\n",test_sao_top_post.sao_mode[1],test_sao_top_post.sao_type[1],test_sao_top_post.typeAuxInfo[1]);
					$fwrite(me,"%d %d %d %d\n",test_sao_top_post.offset[0],test_sao_top_post.offset[1],test_sao_top_post.offset[2],test_sao_top_post.offset[3]);
				end
				else if(cnt==59-SHIFT)	begin
					$fwrite(me,"%d %d %d\n",test_sao_top_post.sao_mode[1],test_sao_top_post.sao_type[1],test_sao_top_post.typeAuxInfo[2]);
					$fwrite(me,"%d %d %d %d\n\n",test_sao_top_post.offset[0],test_sao_top_post.offset[1],test_sao_top_post.offset[2],test_sao_top_post.offset[3]);
					CTU_cnt++;
				end
				
			end
			
			
			
		end
	end
endprogram:tb_deci


module test_sao_top_post();
parameter           CK = 7.8;

logic 		clk,arst_n,rst_n,clk_slow;
logic [5:0] X,Y,X_1,X_2,Y_1,Y_2,X_3,Y_3;

logic   chroma_w;
logic   chroma_w_r1,chroma_w_r2,chroma_w_r3,chroma_w_r4;
logic isWorking_stat_r1,isWorking_stat_r2,isWorking_stat_r3,isWorking_stat_r4;


/*
logic 			[sao_type_len-1:0]										sao_type[0:1];
logic 	signed	[offset_len-1:0]										offset[0:n_category-1];
logic 			[1:0]    												sao_mode[0:1];					//0： OFF    1:NEW   2:MERGE
logic 			[$clog2(32)-1:0]   										typeAuxInfo[0:2];
	*/
	
logic 			[sao_type_len-1:0]										sao_type[1:0];
logic 	signed	[offset_len-1:0]										offset[n_category-1:0];
logic 			[1:0]    												sao_mode[1:0];					//0： OFF    1:NEW   2:MERGE
logic 			[$clog2(32)-1:0]   										typeAuxInfo[2:0];
logic   [8:0]															lamda[2:0];

logic 	[pic_width_len-1:0]												pic_width;			
logic 	[pic_height_len-1:0]											pic_height;



logic	[blk_22_X_len-1:0]					X_;
logic	[blk_22_X_len-1:0]					Y_;
logic 										en_i,en_o,en_o_2;

logic 	[cut_x_len-1:0]						ctu_x;
logic 	[cut_y_len-1:0]						ctu_y;
logic   [2:0]								ctb_size_log2;
logic 	[bit_depth-1:0] 					n_org_m[0:n_pix-1];	
logic 	[bit_depth-1:0] 					rec_in[0:n_pix-1][0:n_pix-1];
logic	[2:0]								ctu_size;

logic   [1:0]								cIdx_dc,cIdx;
logic	[5:0]								cnt_dc;
logic	[9:0]								cnt_st;
logic										wait_forPre;

logic signed [num_pix_CTU_log2*2+diff_clip_bit:0]						sum_blk_CTU[0:n_eo_type-1][0:n_category-1];
logic 	[num_pix_CTU_log2*2:0]										num_blk_CTU[0:n_eo_type-1][0:n_category-1];

logic signed [num_pix_CTU_log2*2+diff_clip_bit:0]						sum_blk_CTU_bo[0:n_category_bo-1];
logic 	[num_pix_CTU_log2*2:0]										num_blk_CTU_bo[0:n_category_bo-1];

///assign cIdx =  sao_top.sao_FSM.cIdx;

assign 	chroma_w = sao_top_clk.wait_forPre;
assign isWorking_stat_r1 = sao_top_clk.sao_top_isWorking_stat_r1;


initial begin
  clk = 0; 
  #(CK/2.0) 
  forever begin 
	#(CK/2.0) clk = ~clk;
  end
  
  		$read_lib_saif("power_fwd.saif");
		$read_lib_saif("power_fwd_M.saif");
		//monitor gates=ON to record toggles
		$set_gate_level_monitoring("ON");
		$sdf_annotate("/home/jianbin/SAO/hw/syn/20160104/0.7/sao_top_clk_postLayout.sdf", test_sao_top_post.sao_top_clk);
		//specify part of the design for which toggle info is collected - for entire design use UUT_DESIGN
		$set_toggle_region(test_sao_top_post.sao_top_clk);
		
		//start toggle recording
		$toggle_start();
		
		$toggle_stop();
		$toggle_report("power_back.saif", 1.0e-9,"test_sao_top_post.sao_top_clk");
end

initial begin
  clk_slow = 0; 
  #(CK/2.0) 
  forever begin 
	#(CK*3) clk_slow = ~clk_slow;
  end
end




initial begin
	arst_n = 0;
	rst_n =0;
	en_i = 1;
	en_o = 1;
	en_o_2 = 1;
	pic_width = 13'd832;
	pic_height = 13'd480;
	ctb_size_log2 = 6;
	ctu_size= 6;
	
	
	#CK arst_n = 1;
	#CK rst_n = 1;
	
end

always_ff @(posedge clk) begin
/*	{X} <= {sao_top_clk.sao_top.X};
	{Y}	<= {sao_top_clk.sao_top.Y};
	{X_1,Y_1} <= {X,Y};
	{X_2,Y_2} <= {X_1,Y_1};
	{X_3,Y_3} <= {X_2,Y_2};*/
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
	.clk(sao_top_clk.clk_slow)
);

sao_top_clk sao_top_clk(
	.clk,
//	.clk_slow,
	.arst_n,
	.rst_n,
	.sao_type,
	.sao_mode,
	.typeAuxInfo,
	.offset,
	//.X_0(X_),
//	.Y_0(Y_),
	.en_i,
	.en_o,
	//.en_o_2,
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
	.cIdx,
	.cIdx_dc,
	.*
);

endmodule