/*
luma : 64x64 CTB,   X: 0~29, Y:0~29
chroma : 32x32 CTB,   X: 0~14, Y:0~14

en_i : the front is en or not, if en_i is 0, the FSM go into IDLE.
en_o : the end is en or not,  if en_o is 0, all the registers don't transfer signal.
*/
`timescale 1ns/1ps
`ifndef P7_BO_REDUCED
`define P7_BO_REDUCED 1
`endif
module sao_FSM #(
parameter luma_wait_cycle =35,// 34,
parameter chroma_wait_cycle = 30,
parameter luma_BO_collect_cycle = 32,
parameter chroma_BO_collect_cycle = 16,
parameter SHIFT = 24,
parameter num_cycle_luma_st = 870+luma_wait_cycle,		//29x30
parameter num_cycle_luma_dc = 64-SHIFT,		
parameter num_cycle_chroma_st = 210+chroma_wait_cycle,	//14x15=210
parameter num_cycle_chroma_dc = 60-SHIFT,	   	//60
parameter blk_22_X_len = 6,
parameter blk_22_Y_len = 6,
parameter cnt_st_len = 10,
parameter cut_x_len = 9,
parameter cut_y_len = 9,
parameter REFRESH_CYCLE = 22
)
(
	input 	logic				clk,arst_n,rst_n,en_i,en_o,
	input   logic	[2:0]		ctb_size_log2,
	input	logic 	[cut_x_len-1:0]					ctu_x,
	input	logic 	[cut_y_len-1:0]					ctu_y,
	input	logic [4:0] 							X_len,
	input	logic [4:0] 							Y_len,
	input 	logic									isWorking_deci,
	
	output	logic	[blk_22_X_len-1:0]				X,
	output	logic	[blk_22_Y_len-1:0]				Y,

	output 	logic									isWorking_stat,
	output  logic   								wait_forPre,
	output  logic   								is_bo_pre,
	output 	logic									not_end,
	output	logic   								isToRefresh,
`ifdef P7_BO_REDUCED
	output	logic									not_end_pre_stage,
`endif
	output 	logic	[1:0]							cIdx,
	output	logic									end_of_luma_st,
	output	logic									end_of_chroma_st,
	output	logic									able_to_pass,
	output	logic									end_s,
	output  logic 	[cnt_st_len-1:0]				cnt_st
);


logic	[blk_22_X_len-1:0]					X_;
logic	[blk_22_Y_len-1:0]					Y_;
logic 	[cnt_st_len-1:0]					cnt_st_;

enum logic	{IDLE,WORK}						state_st,n_state_st;



assign	isToRefresh = (isWorking_stat && cnt_st == REFRESH_CYCLE);

assign  wait_forPre = (cIdx && cnt_st<chroma_wait_cycle) || (!cIdx && cnt_st<luma_wait_cycle);			//in chroma stat. stage, the first 30 cycles do nothing.
assign 	is_bo_pre = (!cIdx && cnt_st<luma_BO_collect_cycle) || (cIdx && cnt_st<chroma_BO_collect_cycle);
logic										not_end_;
assign not_end =  not_end_ ;//&& !wait_forPre;
assign isWorking_stat = (state_st == WORK);

logic 								end_of_luma_st_;

assign end_of_luma_st_ = !cIdx && cnt_st == num_cycle_luma_st-1;
assign end_of_chroma_st_ = cIdx>0 && cnt_st < chroma_wait_cycle+12 && cnt_st > chroma_wait_cycle;
logic       n_initial;

assign able_to_pass = ((cnt_st > num_cycle_luma_st-6) || (cIdx && cnt_st> num_cycle_chroma_st-6)) ||  cnt_st<REFRESH_CYCLE-6;



always_ff @(posedge clk or negedge arst_n) 
	if(!arst_n)begin
		 state_st <= IDLE;
		 {cIdx,cnt_st,X,Y,end_s} <=0;
		 not_end_ <= 1;
		 n_initial <= 0;
`ifdef P7_BO_REDUCED
		 not_end_pre_stage <= 1;
		 `endif
		 end_of_luma_st <= 0;
		 end_of_chroma_st <= 0;
	end
	else if(!rst_n)	begin
		 state_st <= IDLE;
		 {cIdx,cnt_st,X,Y,end_s} <=0;
		 not_end_ <= 1;
		 n_initial <= 0;
`ifdef P7_BO_REDUCED
		 not_end_pre_stage <= 1;
		 `endif
		 end_of_luma_st <= 0;
		 end_of_chroma_st <= 0;
	end
	else	begin
		if( en_o)	begin
			 state_st <=  n_state_st;
			 cnt_st <= cnt_st_;
			 {X,Y}<={X_,Y_};
			 if(end_of_luma_st_)
				end_of_luma_st <= 1;
			else if(isWorking_deci)
				end_of_luma_st <= 0;
				
			if(end_of_chroma_st_)
				end_of_chroma_st <= 1;
			else if(isWorking_deci)
				end_of_chroma_st <= 0;
			
			if(end_of_luma_st_)	begin
				cIdx <= 1;
				end
			else if( cIdx==2'b01 &&  cnt_st == num_cycle_chroma_st-1)
				cIdx <= 2;
			else if( cIdx==2'b10 &&  cnt_st == num_cycle_chroma_st-1)
				cIdx <= 0;
			 
			if(n_initial && cnt_st == 8)
				end_s <= 1;
			else if(isWorking_deci)
				end_s <= 0;
			
			not_end_ <= ((state_st == IDLE) || (!cIdx? (cnt_st!= num_cycle_luma_st-1) : (cnt_st!= num_cycle_chroma_st-1)));
			`ifdef P7_BO_REDUCED
			not_end_pre_stage <= ((!cIdx? (cnt_st!= luma_BO_collect_cycle-1) : (cnt_st!= chroma_BO_collect_cycle-1)));
			`endif
			
			
			if(cnt_st>50)
				n_initial <= 1;
			
		end
	
	end
	



always_comb	begin
	n_state_st = IDLE;
	cnt_st_ =  cnt_st;
	X_ = X;
	Y_ = Y;
	
	case ( state_st)
		IDLE:	begin
			if(en_i)
				 n_state_st = WORK;
		end
		WORK:	begin			//default: WORK
			if((!cIdx &&  cnt_st != num_cycle_luma_st-1) || 
				(|cIdx &&  cnt_st != num_cycle_chroma_st-1)) 
					cnt_st_ =  cnt_st+1;
				else
					cnt_st_ = 0;
			
			if(X<(X_len) && !wait_forPre)
				X_= X+1;
			else begin
				X_= 0;
				if(Y<(Y_len) && !wait_forPre)
					Y_=Y+1;
				else
					Y_=0; 
			end
			if(en_i)
				 n_state_st = WORK;
			
		end
		default: begin
		
		end
			
	endcase
end


endmodule