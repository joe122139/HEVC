`timescale 1ns/1ps
module sao_stat_boundary #(
	parameter pic_width_len = 13,
	parameter pic_height_len = 13,
	parameter cut_x_len = 9,
	parameter cut_y_len = 9,
	parameter blk_22_X_len = 6,
	parameter blk_22_Y_len = 6
)

(
	input	logic 	[pic_width_len-1:0]				pic_width,	
	input	logic 	[pic_height_len-1:0]			pic_height,
	input	logic 	[cut_x_len-1:0]					ctu_x,
	input	logic 	[cut_y_len-1:0]					ctu_y,
	input	logic	[blk_22_X_len-1:0]				X,
	input	logic	[blk_22_Y_len-1:0]				Y,
	input	logic	[1:0]							cIdx,
	input	logic	[2:0]							ctu_size,
	
	output	logic 									isAboveAvail,
	output	logic 									isLeftAvail,
	output	logic 									isLeftAboveAvail,
	
	output	logic									isLeftMergeAvail,
	output	logic									isUpperMergeAvail,
	output	logic [4:0] 							X_len,
	output	logic [4:0] 							Y_len
);
	logic	[5:0]		pic_height_mod_ctu_height;
	logic	[5:0]		pic_width_mod_ctu_width;
	logic	[8:0]		pic_height_div_ctu_height;
	logic	[8:0]		pic_width_div_ctu_width;
	logic   	[5:0]					mod_height;	
	logic   	[5:0]					mod_width;	
	logic       [8:0]					num_cur_ctu_X;	
	logic       [8:0]					num_cur_ctu_Y;	
	logic	b_w,b_h;	
	
assign pic_height_mod_ctu_height = 	pic_height%(1<<ctu_size);
assign pic_width_mod_ctu_width = 	pic_width%(1<<ctu_size);
assign	pic_height_div_ctu_height =	pic_height>>ctu_size;
assign	pic_width_div_ctu_width =	pic_width>>ctu_size;

logic	isChroma;
assign	isChroma = cIdx? 1:0;

assign mod_height = !cIdx? pic_height_mod_ctu_height: pic_height_mod_ctu_height>>1;
assign mod_width = !cIdx? pic_width_mod_ctu_width: pic_width_mod_ctu_width>>1;
assign num_cur_ctu_X = (ctu_x<<(isChroma))>>(ctu_size-4);
assign num_cur_ctu_Y = (ctu_y<<(isChroma))>>(ctu_size-4);
assign	b_w = !cIdx? mod_width>6 : mod_width>4;
assign	b_h = !cIdx? mod_height>4 : mod_height>2;

always_comb begin
//	if(pic_width_div_ctu_width==num_cur_ctu_X && b_w)	//On the boundary of picture
//		X_len = !cIdx? (mod_width>>1)-4:(mod_width>>2)-3;
//	else
		X_len = !cIdx? 5'd28:5'd13;
		
//	if(pic_height_div_ctu_height== num_cur_ctu_Y && b_h)	
//		Y_len = !cIdx? (mod_height>>1)-3:(mod_height>>2)-2; 
//	else
		Y_len = !cIdx? 5'd29:5'd14;
	
end

always_comb
	begin
		 isAboveAvail = 1;
		 isLeftAvail = 1;
		
		if(X==0 && ctu_x==0)
			 isLeftAvail = 0;
			
		if(Y==0 && ctu_y==0)
			  isAboveAvail = 0;
	
		 isLeftAboveAvail =  isLeftAvail &&  isAboveAvail;
		 
		 isLeftMergeAvail =  !ctu_x? 0: 1;
		 isUpperMergeAvail = !ctu_y? 0: 1;
		 
	end
endmodule