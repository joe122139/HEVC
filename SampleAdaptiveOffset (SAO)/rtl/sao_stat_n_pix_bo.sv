`timescale 1ns/1ps																																								
module sao_stat_n_pix_bo
#(
parameter bit_depth = 8, 
parameter n_pix = 4,
parameter n_bo_type = 5
//,parameter type sample = logic [bit_depth-1:0], 
//parameter type sign_sample = logic [bit_depth:0]
)
(
	input logic 	[bit_depth-1:0] 				n_rec_m[0:n_pix-1],
	output logic  	[n_bo_type-1:0]					bo_cate [0:n_pix-1]
);

generate
for(genvar i=0;i<n_pix;i=i+1) begin:xi	
		sao_stat_BO_classify BO_cate(
			.rec(n_rec_m[i]),
			.bo_catagory(bo_cate[i])
			);
end
endgenerate

		


endmodule
