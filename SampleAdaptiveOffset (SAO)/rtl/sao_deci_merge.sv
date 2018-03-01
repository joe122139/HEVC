`timescale 1ns/1ps
module sao_deci_merge#(
parameter SHIFT = 24,
parameter n_category_bo = 8,
parameter n_sao_type = 3,
parameter n_offset = 4,
parameter offset_len = 4,
parameter state_len = 6,
parameter DW = 26,
parameter AW = 9,//11,
parameter ctu_x_len 	= 9,
parameter ctu_y_len 	= 9,
parameter n_category = 4,
parameter n_eo_type = 4,
parameter MERGE_LE_BEGIN = 48-SHIFT,
parameter MERGE_LE_END = 51-SHIFT,
parameter MERGE_UP_BEGIN = 52-SHIFT,
parameter MERGE_UP_END = 55-SHIFT
)(
	input	logic																		clk,arst_n,rst_n,en,
	input	logic			[state_len-1:0]												cnt_dc_r,
	input	logic			[state_len-1:0]												cnt_dc_w,
	input	logic			[n_sao_type-1:0]											cur_merge_sao_type[0:1],
	input	logic			[1:0]														cur_merge_sao_mode[0:1],
	input	logic			[$clog2(8)-1:0]												cur_typeAuxInfo[0:2],
	input	logic			[$clog2(32)-1:0]											typeAuxInfo_w[0:2],
	input	logic			[ctu_x_len-1:0]												cur_ctu_x,
	input	logic			[ctu_y_len-1:0]												cur_ctu_y,
	input	logic			[1:0]														cIdx,
	input	logic 	signed 	[offset_len-1:0]											offset_eo[0:1][0:n_eo_type-1][0:n_category-1],
	input	logic 	signed 	[offset_len-1:0]											offset_bo[0:1][0:n_category_bo-1],
	input	logic																		isLeftMergeAvail,
	input	logic																		isUpperMergeAvail,

	output	logic	signed	[offset_len-1:0]											merge_offset[0:n_offset-1],
	output	logic			[n_sao_type-1:0]											L_merge_sao_type[0:1],
	output	logic			[1:0]														L_merge_sao_mode[0:1],
	output	logic			[$clog2(32)-1:0]											L_typeAuxInfo[0:2],
	output	logic			[n_sao_type-1:0]											U_merge_sao_type[0:1],
	output	logic			[1:0]														U_merge_sao_mode[0:1],
	output	logic			[$clog2(32)-1:0]											U_typeAuxInfo[0:2],
	output 	logic	signed	[offset_len-1:0]											offset_toStore[0:n_offset-1]
);




	logic			[$clog2(32)-1:0]													sao_typeAuxInfo_toStore[0:2];
	logic	signed	[offset_len-1:0]													L_offset[0:2][0:n_offset-1];
	

	logic	signed	[offset_len-1:0]													U_offset[0:2][0:n_offset-1];

	
	logic			[n_sao_type-1:0]													sao_type_toStore;
	logic			[1:0]																sao_mode_toStore;
	
	logic			[n_sao_type-1:0]													sao_type_new_L;
	logic			[1:0]																sao_mode_new_L;
	logic	signed	[offset_len-1:0]													offset_new_L[0:n_offset-1];
	
	logic 			[DW-1:0] 															wdata;
	logic 			[DW-1:0] 															rdata;
	logic																				isChroma;		
	logic   		[AW-1:0]															addr;
	logic 			[AW-1:0]															addr_;
	logic																				we_n,re_n;
	logic   		[9:0]					shift;
	assign 		isChroma	=	|cIdx;
/*
stdcore_spram #(.DW(DW),.AW(AW),.DEPTH(360)) stdcore_spram(
	.clk,
    .ce_n(re_n),
	.we_n,
	.rdata,
	.wdata,
	.addr
);
*/
rf_sp_26x360m4 #(.DW(DW),.AW(AW),.DEPTH(360)) stdcore_spram(
	.CLK(clk),
    .CEN(re_n),
	.WEN(we_n),
	.Q(rdata),
	.D(wdata),
	.A(addr)
);
	
	
	always_comb begin
		{sao_typeAuxInfo_toStore[0],sao_typeAuxInfo_toStore[1],sao_typeAuxInfo_toStore[2]} =0;
		sao_type_toStore = 0;
		sao_mode_toStore = 0;
		{offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]} = 0;
		if(cnt_dc_w==MERGE_UP_END+2)	begin		//write Luma
			if(cur_merge_sao_mode[0]==1) begin			//mode: NEW
				sao_type_toStore = cur_merge_sao_type[0];
				sao_mode_toStore = cur_merge_sao_mode[0];
				{offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]} = {offset_new_L[0],offset_new_L[1],offset_new_L[2],offset_new_L[3]};   //{offset_bo[0][cur_typeAuxInfo[0]],offset_bo[0][cur_typeAuxInfo[0]+1],offset_bo[0][cur_typeAuxInfo[0]+2],offset_bo[0][cur_typeAuxInfo[0]+3]};
				sao_typeAuxInfo_toStore[0] = typeAuxInfo_w[0];
			end
			else if(cur_merge_sao_mode[0]==2) begin
				if(cur_merge_sao_type[0]==0)	begin		//current is merging left. 
					sao_type_toStore = L_merge_sao_type[0];
					sao_mode_toStore = L_merge_sao_mode[0];
					{offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]} =  {L_offset[0][0],L_offset[0][1],L_offset[0][2],L_offset[0][3]};  
					sao_typeAuxInfo_toStore[0] = L_typeAuxInfo[0];
				end else begin
					sao_type_toStore = U_merge_sao_type[0];
					sao_mode_toStore = U_merge_sao_mode[0];
					{offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]} = {U_offset[0][0],U_offset[0][1],U_offset[0][2],U_offset[0][3]};
					sao_typeAuxInfo_toStore[0] = U_typeAuxInfo[0];
				end
			end
		end
		if(cnt_dc_w==MERGE_UP_END+3) begin		//write cb
			if(cur_merge_sao_mode[1]==1) begin			//mode: NEW
				sao_type_toStore = cur_merge_sao_type[1];
				sao_mode_toStore = cur_merge_sao_mode[1];
				if(cur_merge_sao_type[1][2])	begin		//cur_merge_sao_type[0]==4		//BO
					{offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]} = {offset_bo[0][cur_typeAuxInfo[1]],offset_bo[0][cur_typeAuxInfo[1]+1],offset_bo[0][cur_typeAuxInfo[1]+2],offset_bo[0][cur_typeAuxInfo[1]+3]};
					sao_typeAuxInfo_toStore[1] = typeAuxInfo_w[1];
				end
				else				//EO
					{offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]} = {offset_eo[0][cur_merge_sao_type[1]][0],offset_eo[0][cur_merge_sao_type[1]][1],offset_eo[0][cur_merge_sao_type[1]][2],offset_eo[0][cur_merge_sao_type[1]][3]};
			end
			else if(cur_merge_sao_mode[1]==2) begin
				if(cur_merge_sao_type[1]==0)	begin		//current is merging left. 
					sao_type_toStore = L_merge_sao_type[1];
					sao_mode_toStore = L_merge_sao_mode[1];
					{offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]} = {L_offset[1][0],L_offset[1][1],L_offset[1][2],L_offset[1][3]};   
					sao_typeAuxInfo_toStore[1] = L_typeAuxInfo[1];
				end else begin
					sao_type_toStore = U_merge_sao_type[1];
					sao_mode_toStore = U_merge_sao_mode[1];
					{offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]} ={U_offset[1][0],U_offset[1][1],U_offset[1][2],U_offset[1][3]};   
					sao_typeAuxInfo_toStore[1] = U_typeAuxInfo[1];
				end
			end

		end
		
		if(cnt_dc_w==MERGE_UP_END+4) begin		//write Cr
			if(cur_merge_sao_mode[1]==1) begin			//mode: NEW
				sao_type_toStore = cur_merge_sao_type[1];
				sao_mode_toStore = cur_merge_sao_mode[1];
				if(cur_merge_sao_type[1][2])	begin		//cur_merge_sao_type[0]==4		//BO
					{offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]} = {offset_bo[1][cur_typeAuxInfo[2]],offset_bo[1][cur_typeAuxInfo[2]+1],offset_bo[1][cur_typeAuxInfo[2]+2],offset_bo[1][cur_typeAuxInfo[2]+3]};
					sao_typeAuxInfo_toStore[2] = typeAuxInfo_w[2];
				end
				else				//EO
					{offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]} = {offset_eo[1][cur_merge_sao_type[1]][0],offset_eo[1][cur_merge_sao_type[1]][1],offset_eo[1][cur_merge_sao_type[1]][2],offset_eo[1][cur_merge_sao_type[1]][3]};
			end
			else if(cur_merge_sao_mode[1]==2) begin
				if(cur_merge_sao_type[1]==0)	begin		//current is merging left. 
					sao_type_toStore = L_merge_sao_type[1];
					sao_mode_toStore = L_merge_sao_mode[1];
					{offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]} = {L_offset[2][0],L_offset[2][1],L_offset[2][2],L_offset[2][3]};   
					sao_typeAuxInfo_toStore[2] = L_typeAuxInfo[2];
				end else begin
					sao_type_toStore = U_merge_sao_type[1];
					sao_mode_toStore = U_merge_sao_mode[1];
					{offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]} ={U_offset[2][0],U_offset[2][1],U_offset[2][2],U_offset[2][3]};   
					sao_typeAuxInfo_toStore[2] = U_typeAuxInfo[2];
				end
			end
		end
				
	
		//!! the L_offset seems to be modified in Y and Cb.
		{merge_offset[0],merge_offset[1],merge_offset[2],merge_offset[3]} = 0;
		if(cnt_dc_r>MERGE_LE_BEGIN-1 && cnt_dc_r<MERGE_UP_BEGIN && isLeftMergeAvail)	begin
			{merge_offset[0],merge_offset[1],merge_offset[2],merge_offset[3]} = {L_offset[cIdx][0],L_offset[cIdx][1],L_offset[cIdx][2],L_offset[cIdx][3]};
			
		end
		if(cnt_dc_r>MERGE_UP_BEGIN-1 && cnt_dc_r <= MERGE_UP_END && isUpperMergeAvail)	begin
			{merge_offset[0],merge_offset[1],merge_offset[2],merge_offset[3]} = {U_offset[cIdx][0],U_offset[cIdx][1],U_offset[cIdx][2],U_offset[cIdx][3]};
		end
	
	end
	
	
	always_ff @(posedge clk or negedge arst_n)
		if(!arst_n) begin
			{L_merge_sao_mode[0],L_merge_sao_type[0],L_typeAuxInfo[0]} <= 0;
			{L_merge_sao_mode[1],L_merge_sao_type[1],L_typeAuxInfo[1]} <= 0;
			{L_typeAuxInfo[2]} <= 0;
		
			{U_merge_sao_mode[0],U_merge_sao_type[0],U_typeAuxInfo[0]} <= 0;
			{U_merge_sao_mode[1],U_merge_sao_type[1],U_typeAuxInfo[1]} <= 0;
								{U_typeAuxInfo[2]} <= 0;
			
			{L_offset[0][0],L_offset[0][1],L_offset[0][2],L_offset[0][3]}<=0;
			{L_offset[1][0],L_offset[1][1],L_offset[1][2],L_offset[1][3]}<=0;
			{L_offset[2][0],L_offset[2][1],L_offset[2][2],L_offset[2][3]}<=0;
			
			{U_offset[0][0],U_offset[0][1],U_offset[0][2],U_offset[0][3]}<=0;
			{U_offset[1][0],U_offset[1][1],U_offset[1][2],U_offset[1][3]}<=0;
			{U_offset[2][0],U_offset[2][1],U_offset[2][2],U_offset[2][3]}<=0;
			{offset_new_L[0],offset_new_L[1],offset_new_L[2],offset_new_L[3]}<=0;
			wdata <= 0;
			addr <=0;
			we_n <=1;
			re_n <=1;
		end
		else if(!rst_n) begin
			{L_merge_sao_mode[0],L_merge_sao_type[0],L_typeAuxInfo[0]} <= 0;
			{L_merge_sao_mode[1],L_merge_sao_type[1],L_typeAuxInfo[1]} <= 0;
			{L_typeAuxInfo[2]} <= 0;
		
			{U_merge_sao_mode[0],U_merge_sao_type[0],U_typeAuxInfo[0]} <= 0;
			{U_merge_sao_mode[1],U_merge_sao_type[1],U_typeAuxInfo[1]} <= 0;
								{U_typeAuxInfo[2]} <= 0;
			
			{L_offset[0][0],L_offset[0][1],L_offset[0][2],L_offset[0][3]}<=0;
			{L_offset[1][0],L_offset[1][1],L_offset[1][2],L_offset[1][3]}<=0;
			{L_offset[2][0],L_offset[2][1],L_offset[2][2],L_offset[2][3]}<=0;
			
			{U_offset[0][0],U_offset[0][1],U_offset[0][2],U_offset[0][3]}<=0;
			{U_offset[1][0],U_offset[1][1],U_offset[1][2],U_offset[1][3]}<=0;
			{U_offset[2][0],U_offset[2][1],U_offset[2][2],U_offset[2][3]}<=0;
			{offset_new_L[0],offset_new_L[1],offset_new_L[2],offset_new_L[3]}<=0;
			
			wdata <= 0;
			addr<=0;
			we_n<=1;
			re_n<=1;
		end
		else begin
			if(en) begin
				if((cnt_dc_r==MERGE_UP_BEGIN-3 && isUpperMergeAvail) || (cnt_dc_w==MERGE_UP_END+2 || cnt_dc_w==MERGE_UP_END+3 ||cnt_dc_w==MERGE_UP_END+4 ))
					addr <= addr_;
				if(cnt_dc_r==MERGE_UP_BEGIN-3 && isUpperMergeAvail ||(cnt_dc_w==MERGE_UP_END+2 || cnt_dc_w==MERGE_UP_END+3 ||cnt_dc_w==MERGE_UP_END+4 ) ) 
					re_n <=0;
				else
					re_n <= 1;
				//	addr <= (cur_ctu_x<<(isChroma));
				
		
				//read,	taking 2 cycles
				if(cnt_dc_r ==MERGE_UP_BEGIN-1 && isUpperMergeAvail) begin
					{U_merge_sao_mode[isChroma],U_merge_sao_type[isChroma],U_typeAuxInfo[cIdx],U_offset[cIdx][0],U_offset[cIdx][1],U_offset[cIdx][2],U_offset[cIdx][3]}<=  rdata;
				end 
				if(!cIdx && cnt_dc_w==MERGE_UP_END+2)	begin
					if(cur_merge_sao_type[0][2])  //bo
						{offset_new_L[0],offset_new_L[1],offset_new_L[2],offset_new_L[3]}<={offset_bo[0][cur_typeAuxInfo[0]],offset_bo[0][cur_typeAuxInfo[0]+1],offset_bo[0][cur_typeAuxInfo[0]+2],offset_bo[0][cur_typeAuxInfo[0]+3]};
					else
						{offset_new_L[0],offset_new_L[1],offset_new_L[2],offset_new_L[3]}<={offset_eo[0][cur_merge_sao_type[0]][0],offset_eo[0][cur_merge_sao_type[0]][1],offset_eo[0][cur_merge_sao_type[0]][2],offset_eo[0][cur_merge_sao_type[0]][3]};
				end
			
				if(cIdx[1])	begin
					if(cnt_dc_w==MERGE_UP_END+2 )	begin		//write Lu
						if(cur_merge_sao_type[0]!=0 || cur_merge_sao_mode[0]!=2)	begin
							{L_merge_sao_mode[0],L_merge_sao_type[0],L_typeAuxInfo[0]} <= {sao_mode_toStore,sao_type_toStore,sao_typeAuxInfo_toStore[0]};
							{L_offset[0][0],L_offset[0][1],L_offset[0][2],L_offset[0][3]} <= {offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]};
						end
						if(cur_merge_sao_type[0]!=1 || cur_merge_sao_mode[0]!=2)	begin
							 wdata <= {sao_mode_toStore,sao_type_toStore,sao_typeAuxInfo_toStore[0],offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]};	
							 we_n <= 0;
						end
						else
							we_n <= 1;
						//else if cur_merge_sao_mode[0] == 2,  no need to update L and SRAM.
					end 
					else if(cnt_dc_w==MERGE_UP_END+3)	begin	//write Cb				Attention! cannot update L_merge_sao_mode[1],L_merge_sao_type[1] here, because when cnt_dc_w== MERGE_UP_END+4, it is used.
						if(cur_merge_sao_type[1]!=0 || cur_merge_sao_mode[1]!=2)	begin
							L_typeAuxInfo[1] <= sao_typeAuxInfo_toStore[1];
							{L_offset[1][0],L_offset[1][1],L_offset[1][2],L_offset[1][3]} <= {offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]};
						end
						if(cur_merge_sao_type[1]!=1 || cur_merge_sao_mode[1]!=2)	begin
							wdata <= {sao_mode_toStore,sao_type_toStore,sao_typeAuxInfo_toStore[1],offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]};
							we_n <= 0;
						end
						else	we_n <= 1;
					end
					else if(cnt_dc_w==MERGE_UP_END+4)	begin	//write Cr
						if(cur_merge_sao_type[1]!=0 || cur_merge_sao_mode[1]!=2)	begin
							{L_merge_sao_mode[1],L_merge_sao_type[1],L_typeAuxInfo[2]} <= {sao_mode_toStore,sao_type_toStore,sao_typeAuxInfo_toStore[2]};
							{L_offset[2][0],L_offset[2][1],L_offset[2][2],L_offset[2][3]} <= {offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]};
						end
						if(cur_merge_sao_type[1]!=1 || cur_merge_sao_mode[1]!=2)	begin
							wdata <= {sao_mode_toStore,sao_type_toStore,sao_typeAuxInfo_toStore[2],offset_toStore[0],offset_toStore[1],offset_toStore[2],offset_toStore[3]};
						//	addr <= (cur_ctu_x<<1)+2;
							we_n <= 0;
						end
						else we_n <= 1;
					end
					else 
						we_n <= 1;
				end
				else 
					we_n <=1;
			end
		end	

		always_comb begin
			addr_ = 0;
			shift = 0;
			if(cIdx == 1)
				shift = 120;//480;
			else if(cIdx==2)
				shift = 240;//960;
			if(isUpperMergeAvail) begin
				if(cnt_dc_r==MERGE_UP_BEGIN-3)
					addr_= (cur_ctu_x>>2)+shift;
			end
			if(cnt_dc_w==MERGE_UP_END+2)
				addr_ = cur_ctu_x>>2;
			if (cnt_dc_w==MERGE_UP_END+3)
			//	addr_ = (cur_ctu_x<<1)+480;
				addr_ = (cur_ctu_x>>2)+120;
			if(cnt_dc_w==MERGE_UP_END+4)
			//	addr_ = (cur_ctu_x<<1)+960;
				addr_ = (cur_ctu_x>>2)+240;
		end
	
endmodule