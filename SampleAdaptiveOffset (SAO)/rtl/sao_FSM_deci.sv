/*
luma : 64x64 CTB,   X: 0~29, Y:0~29
chroma : 32x32 CTB,   X: 0~14, Y:0~14

en_i : the front is en or not, if en_i is 0, the FSM go into IDLE.
en_o : the end is en or not,  if en_o is 0, all the registers don't transfer signal.
*/
`timescale 1ns/1ps

module sao_FSM_deci #(
parameter luma_wait_cycle = 34,
parameter chroma_wait_cycle = 30,
parameter luma_BO_collect_cycle = 32,
parameter chroma_BO_collect_cycle = 16,
parameter SHIFT = 24,
parameter num_cycle_luma_st = 870+luma_wait_cycle,		//29x30
parameter num_cycle_luma_dc = 64-SHIFT,		
parameter num_cycle_chroma_st = 210+chroma_wait_cycle,	//14x15=210
parameter num_cycle_chroma_dc = 60-SHIFT,	   	//60
parameter cnt_dc_len = 6,
parameter REFRESH_CYCLE = 22
)
(
	input 	logic				clk,arst_n,rst_n,en_i,en_o,
	input	logic				end_s,

	output  logic 	[cnt_dc_len-1:0]				cnt_dc_fsm,
	output 	logic									isWorking_deci,
	output 	logic	[1:0]							cIdx_fsm
);



logic 	[cnt_dc_len-1:0]					cnt_dc,cnt_dc_;
enum logic	{IDLE,WORK}						state_dc,n_state_dc;

logic	[1:0]							cIdx;
assign isWorking_deci = (state_dc == WORK);

	always_ff @(posedge clk or negedge arst_n) 
	if(!arst_n)begin
		 state_dc <= IDLE;
		 {cnt_dc,cnt_dc_fsm,cIdx,cIdx_fsm} <=0;
	end
	else if(!rst_n)	begin
		 state_dc <= IDLE;
		 {cnt_dc,cnt_dc_fsm,cIdx,cIdx_fsm} <=0;
	end
	else	begin
		if(en_o)	begin
			 state_dc <= n_state_dc;
			 cnt_dc <= cnt_dc_;
			 cnt_dc_fsm <= cnt_dc;
			 cIdx_fsm <= cIdx;
			if((cnt_dc == num_cycle_chroma_dc-1 && cIdx==2'd1) || (cnt_dc == num_cycle_luma_dc-1 && !cIdx[1]))
				cIdx <= cIdx+1;
			else if(cIdx==2'd2 && cnt_dc == num_cycle_chroma_dc-1)
				cIdx <= 0;
			
		end
	
	end

always_comb	begin
	cnt_dc_ =  cnt_dc;	
	//state_dc
	n_state_dc = IDLE;
	case ( state_dc)
		IDLE:	begin
			if(en_o && end_s)
				 n_state_dc = WORK;
		end
		WORK:	begin			//default: WORK
			if( cnt_dc == num_cycle_luma_dc-1 || (cIdx && cnt_dc==num_cycle_chroma_dc-1)) 
				cnt_dc_ = 0;
			else 
				cnt_dc_ =  cnt_dc+1;
			
			if(en_o)
				 n_state_dc = WORK;
			if(cIdx && cnt_dc==num_cycle_chroma_dc-1)
				n_state_dc = IDLE;
		end
		default:begin
		end	
	endcase
end


endmodule