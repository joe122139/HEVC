`timescale 1ns/1ps
module test_sao_deci_init_offset();

parameter           CK = 10.0;
parameter num_pix_CTU_log2 = 5;
parameter num_CTU = num_pix_CTU_log2*2;
parameter offset_len = 4;
parameter sum_CTU_len = num_CTU+offset_len;

logic [num_CTU-1:0] num_blk_CTU;
logic signed [sum_CTU_len-1:0] sum_blk_CTU;
logic signed [offset_len-1:0]	init_offset;
logic signed [offset_len-1:0]	test_offset;

logic  clk;
 
initial begin
num_blk_CTU = 0;
sum_blk_CTU = 0;
end
			sao_deci_init_offset  sao_deci_init_offset(
				.*
			);
			
initial begin
  clk = 0; #(CK/2.0) forever #(CK/2.0) clk = ~clk;
end

initial begin
 forever @ (posedge clk) begin
	 sum_blk_CTU = {$random}%100*-1; 
	 num_blk_CTU = {$random}%10;
	 	$display ("%d,%d\t",sum_blk_CTU,num_blk_CTU); 
	 if (num_blk_CTU) begin
		 if(sum_blk_CTU / num_blk_CTU >7) test_offset = 7;
		 else begin 
			 if(sum_blk_CTU % num_blk_CTU >= (num_blk_CTU+1)>>1 ) 
				test_offset = sum_blk_CTU / num_blk_CTU == 7? 7:(sum_blk_CTU / num_blk_CTU + 1);
			 else
				test_offset = sum_blk_CTU / num_blk_CTU;
			end
		 #1 $display("~~%d,%d", test_offset, init_offset);
		 assert (test_offset == init_offset)
		//	$display ("Pass..."); 
	//else $error("%d,%d, test!=init",test_offset,init_offset) 
		else $error("test!=init, %d!=%d", test_offset, init_offset);
	 end
	 else continue;
 
 end
			
end	

endmodule