`timescale 1ns/1ps
module sao_stat_rec_matching
#(
parameter n_pix=4,
parameter org_window_width = 4,
parameter org_window_height = n_pix/org_window_width,
parameter bit_depth = 8,
parameter EO_TYPE = 0)
(
	input logic 	[bit_depth-1:0] 				rec_in[0:org_window_height+1][0:org_window_width+1],
	
	output	logic 	[bit_depth-1:0] 				n_rec_l[0:n_pix-1],
	output	logic 	[bit_depth-1:0] 				n_rec_r[0:n_pix-1]
);

always_comb begin
	n_rec_l[0]= 0;
	n_rec_l[1]= 0;
	n_rec_l[2]= 0;
	n_rec_l[3]= 0;
	n_rec_r[0]= 0;
	n_rec_r[1]= 0;
	n_rec_r[2]= 0;
	n_rec_r[3]= 0;
	 
	case(EO_TYPE)
	2'd0:		//EO_0
		begin
			 n_rec_l[0]= rec_in[1][0];
			 n_rec_l[1]= rec_in[1][1];
			 n_rec_l[2]= rec_in[2][0];
			 n_rec_l[3]= rec_in[2][1];
			
			 n_rec_r[0]= rec_in[1][2];
			 n_rec_r[1]= rec_in[1][3];
			 n_rec_r[2]= rec_in[2][2];
			 n_rec_r[3]= rec_in[2][3];
			 `ifdef PIX_8

			 n_rec_l[4]=rec_in[1][2];
			 n_rec_l[5]=rec_in[1][3];
			 n_rec_l[6]=rec_in[2][2];
			 n_rec_l[7]=rec_in[2][3];

			n_rec_r[4]= rec_in[1][4];
			n_rec_r[5]= rec_in[1][5];
			n_rec_r[6]= rec_in[2][4];
			n_rec_r[7]= rec_in[2][5];

			 `endif
		end
		
	2'd1:		//EO_90
		begin
			 n_rec_l[0]= rec_in[0][1];	//up
			 n_rec_l[1]= rec_in[0][2];
			 n_rec_l[2]= rec_in[1][1];
			 n_rec_l[3]= rec_in[1][2];
			
			 n_rec_r[0]= rec_in[2][1];	//down
			 n_rec_r[1]= rec_in[2][2];
			 n_rec_r[2]= rec_in[3][1];
			 n_rec_r[3]= rec_in[3][2];
			 `ifdef PIX_8
			 n_rec_l[4]=rec_in[0][3];
			 n_rec_l[5]=rec_in[0][4];
			 n_rec_l[6]=rec_in[1][3];
			 n_rec_l[7]=rec_in[1][4];

			n_rec_r[4]= rec_in[2][3];
			n_rec_r[5]= rec_in[2][4];
			n_rec_r[6]= rec_in[3][3];
			n_rec_r[7]= rec_in[3][4];

			 `endif
			 
		end

	2'd2:		//EO_135
		begin
			 n_rec_l[0]= rec_in[0][0];
			 n_rec_l[1]= rec_in[0][1];
			 n_rec_l[2]= rec_in[1][0];
			 n_rec_l[3]= rec_in[1][1];
			
			 n_rec_r[0]= rec_in[2][2];
			 n_rec_r[1]= rec_in[2][3];
			 n_rec_r[2]= rec_in[3][2];
			 n_rec_r[3]= rec_in[3][3];
			 `ifdef PIX_8
			 n_rec_l[4]=rec_in[0][2];
			 n_rec_l[5]=rec_in[0][3];
			 n_rec_l[6]=rec_in[1][2];
			 n_rec_l[7]=rec_in[1][3];

			n_rec_r[4]= rec_in[2][4];
			n_rec_r[5]= rec_in[2][5];
			n_rec_r[6]= rec_in[3][4];
			n_rec_r[7]= rec_in[3][5];

			`endif


		end
	3'd3: begin   //EO_45
		 n_rec_l[0]= rec_in[2][0];
		 n_rec_l[1]= rec_in[2][1];
		 n_rec_l[2]= rec_in[3][0];
		 n_rec_l[3]= rec_in[3][1];
		
		 n_rec_r[0]= rec_in[0][2];
		 n_rec_r[1]= rec_in[0][3];
		 n_rec_r[2]= rec_in[1][2];
		 n_rec_r[3]= rec_in[1][3];
		 `ifdef PIX_8
		 n_rec_l[4]=rec_in[2][2];
		 n_rec_l[5]=rec_in[2][3];
		 n_rec_l[6]=rec_in[3][2];
		 n_rec_l[7]=rec_in[3][3];

		n_rec_r[4]= rec_in[0][4];
		n_rec_r[5]= rec_in[0][5];
		n_rec_r[6]= rec_in[1][4];
		n_rec_r[7]= rec_in[1][5];

		 `endif
	end
	default:	
		begin
			 n_rec_l[0]= 0;
			 n_rec_l[1]= 0;
			 n_rec_l[2]= 0;
			 n_rec_l[3]= 0;
			 n_rec_r[0]= 0;
			 n_rec_r[1]= 0;
			 n_rec_r[2]= 0;
			 n_rec_r[3]= 0;

			 `ifdef PIX_8
			 n_rec_l[4]= 0;
			 n_rec_l[5]= 0;
			 n_rec_l[6]= 0;
			 n_rec_l[7]= 0;
			 n_rec_r[4]= 0;
			 n_rec_r[5]= 0;
			 n_rec_r[6]= 0;
			 n_rec_r[7]= 0;
			 `endif
		end

	endcase
end

endmodule