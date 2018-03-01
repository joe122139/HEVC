//`define PIX_8
module sao_stat_accu #(
	parameter diff_clip_bit = 4,
	parameter num_pix_CTU_log2 = 5,
	parameter num_accu_len = num_pix_CTU_log2*2-1,
	parameter eo_cate_len = 3,
	`ifdef PIX_8
	parameter num_pix = 8,
	`else
	parameter num_pix = 4,
	`endif
	parameter num_pix_len = (num_pix>>1),
	parameter size_of_CTU = 64,
	parameter sum_th = (size_of_CTU>>1)*(size_of_CTU>>1)*16-8,
	parameter num_th = (1<<(num_accu_len+1))-4
//	parameter num_th = 2048-4
	)
(
//	input logic signed [diff_clip_bit+1:0]			s01,
//	input logic signed [diff_clip_bit:0]			s1,
//	input logic signed [diff_clip_bit:0]			s0,
`ifdef PIX_8
	input logic signed [diff_clip_bit+3:0]			s81,
	input logic signed [diff_clip_bit+3:0]			s71,
	input logic signed [diff_clip_bit+3:0]			s61,
	input logic signed [diff_clip_bit+3:0]			s51,
	input logic signed [diff_clip_bit+2:0]			s41,
	input logic signed [diff_clip_bit+2:0]			s31,
	input logic signed [diff_clip_bit+1:0]			s21,
	input logic signed [diff_clip_bit:0]			s11,
`else
	input logic signed [diff_clip_bit+2:0]			s41,
	input logic signed [diff_clip_bit+2:0]			s31,
	input logic signed [diff_clip_bit+1:0]			s21,
	input logic signed [diff_clip_bit:0]			s11,
`endif
	input logic [num_pix-1:0]						sel,
	input logic   									not_end,		// (cnt != (1<<num_blk_in_CTB_log2)-1);	
	input   logic 									wait_forPre,
	input   logic 									isToRefresh,
	//input   logic 									is_to_pass_data,
`ifdef Four_PIX
	input logic signed [diff_clip_bit+1:0]			s23,
	input logic signed [diff_clip_bit+1:0]			s02,
	input logic signed [diff_clip_bit+1:0]			s03,
	input logic signed [diff_clip_bit+1:0]			s12,
	input logic signed [diff_clip_bit+1:0]			s13,
	
	input logic signed [diff_clip_bit+2:0]			s012,
	input logic signed [diff_clip_bit+2:0]			s013,
	input logic signed [diff_clip_bit+2:0]			s023,
	input logic signed [diff_clip_bit+2:0]			s123,
	
	input logic signed [diff_clip_bit+2:0]			s0123,
	
	input logic signed [diff_clip_bit:0]			s2,
	input logic signed [diff_clip_bit:0]			s3,
`endif
//	input logic [eo_cate_len-1:0]					eo_cate[0:3],
	
	output logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU,
//	output logic signed [num_pix_CTU_log2*2+diff_clip_bit:0]						sum_blk_CTU_DCI,
//	output logic 	[num_pix_CTU_log2*2-1:0]		num_blk_CTU,
	output logic 	[num_accu_len:0]		num_blk_CTU,
//	output logic 	[num_pix_CTU_log2*2-1:0]		num_blk_CTU_DCI,
//	output logic 	[num_pix_CTU_log2*2:0]		num_blk_CTU_DCI,
	
	input  logic  			clk,clk_slow,
	input  logic  			arst_n,
	input  logic  			rst_n,
	input  logic    		en_o
);


logic signed [diff_clip_bit+num_pix_len:0]			sum_blk;
logic signed [diff_clip_bit+num_pix_len:0]			sum_blk_;		//N=4
logic [num_pix_len:0]								num_blk_;
logic [num_pix-1:0]									sel_;

logic 												not_end_;
//logic [num_pix-1:0]									sel;
parameter   num_blk_in_CTB_log2 = 10;
	

	logic    b_accu;
	logic    b_accu_;
	//logic   [num_blk_in_CTB_log2-1:0]  		cnt;
	
//assign not_end = (cnt != (1<<num_blk_in_CTB_log2)-1);	
assign b_accu = |sel;
//assign num_blk = (sel[0] + sel[1]) + (sel[2] +sel[3]);
`ifdef PIX_8
assign num_blk_ = sel_[0]+sel_[1]+sel_[2]+sel_[3]+sel_[4]+sel_[5]+sel_[6]+sel_[7];
`else
assign num_blk_[0] = ^sel_;			
// r1 = A'D(B+C) + BCD' + ABC' + AB'(C+D);
assign num_blk_[1] = (!sel_[0]&&sel_[3]&&(sel_[1]||sel_[2])) || (sel_[1]&&sel_[2]&&(!sel_[3])) || (sel_[0]&&sel_[1]&&(!sel_[2])) || (!sel_[1]&&sel_[0]&&(sel_[2]||sel_[3]));
assign num_blk_[2] = &sel_;
`endif

always_comb begin
	sum_blk = 0;

	casez(sel)
//	casez(sel[3:2])
`ifdef PIX_8
	8'b1???????: begin sum_blk = s81;	end
	8'b01??????: begin sum_blk = s71;	end
	8'b001?????: begin sum_blk = s61;	end
	8'b0001????: begin sum_blk = s51;	end
	8'b00001???: begin sum_blk = s41;	end
	8'b000001??: begin sum_blk = s31;	end
	8'b0000001?: begin sum_blk = s21;	end
	8'b00000001: begin sum_blk = s11;	end
`else
	4'b1???: begin sum_blk = s41;	end
	4'b01??: begin sum_blk = s31;	end
	4'b001?: begin sum_blk = s21;	end
	4'b0001: begin sum_blk = s11;	end
`endif
	default: begin 		end
	endcase
end
	
always_ff @(posedge clk or negedge arst_n)
	if(!arst_n) begin
		{sum_blk_CTU,num_blk_CTU,sum_blk_,sel_,b_accu_} <= 0;
	end
	else if(!rst_n) begin
		{sum_blk_CTU,num_blk_CTU,sum_blk_,sel_,b_accu_} <= 0;
	end
	else begin
		if(en_o) begin
			b_accu_ <= b_accu && not_end && !wait_forPre;
			not_end_ <= not_end;
			sum_blk_ <= sum_blk;
			sel_ <= sel;
			
			if(isToRefresh)	begin
				{sum_blk_CTU,num_blk_CTU} <= 0; 
			end
			else  if(b_accu_) begin
				
				if(num_blk_CTU< num_th)	begin
					sum_blk_CTU <= sum_blk_+sum_blk_CTU;
					num_blk_CTU <= num_blk_ + num_blk_CTU;
				end
			end
		end
	end
endmodule