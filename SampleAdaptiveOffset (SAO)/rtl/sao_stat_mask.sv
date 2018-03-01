`timescale 1ns/1ps
module sao_stat_mask #(
parameter blk_22_X_len = 6,
parameter blk_22_Y_len = 6,
parameter n_pix = 4,
//parameter EO_TYPE = 0
parameter n_eo_type = 4
)
(
	input	logic	[blk_22_X_len-1:0]				X,
	input	logic	[blk_22_Y_len-1:0]				Y,
	input	logic 									isAboveAvail,
	input	logic 									isLeftAvail,
	input	logic 									isLeftAboveAvail,
	
	output 	logic  	[n_pix-1:0]						b_use[0:n_eo_type-1]
);

always_comb begin
	`ifdef PIX_8
	b_use[0] = {8'b11111111};
	b_use[1] = {8'b11111111};
	b_use[2] = {8'b11111111};
	b_use[3] = {8'b11111111};

	`else
	b_use[0] = {4'b1111};
	b_use[1] = {4'b1111};
	b_use[2] = {4'b1111};
	b_use[3] = {4'b1111};

`endif
	if(!isLeftAvail && X==0) begin
		b_use[0][0] = 0;
		b_use[0][2] = 0;
	end
	
	if(!isAboveAvail && Y==0) begin
		b_use[1][0] = 0;
		b_use[1][1] = 0;
		`ifdef PIX_8
		b_use[1][4] = 0;
		b_use[1][5] = 0;
		`endif
	end
	
	if((!isAboveAvail && Y==0) ||(!isLeftAvail && X==0) || (!isLeftAboveAvail && !X && !Y))
		 b_use[2][0] = 0;
			
	if(! isAboveAvail && Y==0)  begin
		b_use[2][1] = 0;
		`ifdef PIX_8
		b_use[2][4] = 0;
		b_use[2][5] = 0;
		`endif
	end

	if(!isLeftAvail && X==0) 
		b_use[2][2] = 0;	
	
	if((!isAboveAvail && Y==0) ||(!isLeftAvail && X==0) || (!isLeftAboveAvail && !X && !Y))
		b_use[3][0] = 0;
			
	if(! isAboveAvail && Y==0)  begin
		b_use[3][1] = 0;
		`ifdef PIX_8
		b_use[3][4] = 0;
		b_use[3][5] = 0;
		`endif
	end

	if(!isLeftAvail && X==0) 
		b_use[3][2] = 0;
	
end		
endmodule 