`timescale 1ns/1ps																																								
module sao_stat_n_pix
#(
parameter bit_depth = 8, 
parameter diff_clip_bit = 4,
parameter n_pix = 4,
parameter EO_TYPE = 0
//,parameter type sample = logic [bit_depth-1:0], 
//parameter type sign_sample = logic [bit_depth:0]
)
(
	input logic 	[bit_depth-1:0] 				n_rec_l[0:n_pix-1],
	input logic 	[bit_depth-1:0] 				n_rec_r[0:n_pix-1],
	input logic 	[bit_depth-1:0] 				n_rec_m[0:n_pix-1],
	output logic  	[2:0]							eo_cate [0:n_pix-1]
);

logic signed [1:0] 	sign_r[0:n_pix-1];
logic signed [1:0] 	sign_l[0:n_pix-1];

logic signed [1:0] 	sign_r_[0:n_pix-1];
logic signed [1:0] 	sign_l_[0:n_pix-1];

always_comb begin
	case(EO_TYPE)
	2'd0:						//EO_0
		begin
			sign_r_[0] = sign_r[0];
			sign_r_[1] = sign_r[1];
			sign_r_[2] = sign_r[2];
			sign_r_[3] = sign_r[3];
			
			sign_l_[0] = sign_l[0];
			sign_l_[1] = (~sign_r[0]+1);//-sign_r[0];
			sign_l_[2] = sign_l[2];
			sign_l_[3] = (~sign_r[2]+1);//-sign_r[2];//
			
		end
	
	2'd1:		//EO_90
		begin
			sign_r_[0] = sign_r[0];
			sign_r_[1] = sign_r[1];
			sign_r_[2] = sign_r[2];
			sign_r_[3] = sign_r[3];
			
			sign_l_[0] = sign_l[0];
			sign_l_[1] = sign_l[1];
			sign_l_[2] = (~sign_r[0]+1);
			sign_l_[3] = (~sign_r[1]+1);
			
		end
	2'd2:			//EO_135
		begin
			sign_r_[0] = sign_r[0];
			sign_r_[1] = sign_r[1];
			sign_r_[2] = sign_r[2];
			sign_r_[3] = sign_r[3];
			
			sign_l_[0] = sign_l[0];
			sign_l_[1] = sign_l[1];
			sign_l_[2] = sign_l[2];
			sign_l_[3] = ~sign_r[0]+1;
			
		end
	default:		//EO_45
		begin
			sign_r_[0] = sign_r[0];
			sign_r_[1] = sign_r[1];
			sign_r_[2] = sign_r[2];
			sign_r_[3] = sign_r[3];
			
			sign_l_[0] = sign_l[0];
			sign_l_[1] = (~sign_r[2]+1);
			sign_l_[2] = sign_l[2];
			sign_l_[3] = sign_l[3];
			
		end
	
	endcase

end

generate
for(genvar i=0;i<n_pix;i=i+1) begin:xi	
		sao_stat_one_pixel_cmp  sao_stat_one_pixel_cmp(
			.rec_l( n_rec_l[i]), 
			.rec_r( n_rec_r[i]), 
			.rec_m( n_rec_m[i]), 
			.sign_l(sign_l[i]),
			.sign_r(sign_r[i])
		);
		
		sao_stat_EO_classify EO_Cat(
	//		.sign_l(sign_l_[i]),
			.sign_l(sign_l[i]),
	//		.sign_r(sign_r_[i]),
			.sign_r(sign_r[i]),
			.eo_catagory(eo_cate[i])
			);
end
endgenerate

		


endmodule
