module test_sao_stat_one_block;
parameter bit_depth = 8;
typedef  logic [bit_depth-1:0] sample;
typedef  logic [bit_depth:0] sign_sample;
sample 				rec_l[0:3][0:3];
sample 				rec_r[0:3][0:3];
sample 				rec_m[0:3][0:3];
sample 				org_m[0:3][0:3];
 logic signed [1:0] 	sign_l[0:3][0:3];
 logic signed [1:0] 	sign_r[0:3][0:3];
 logic signed [4:0]	diff[0:3][0:3];
 
initial begin

for(int i=0;i<4;i++) begin
	for(int j=0;j<4;j++) begin
			rec_l[i][j] = 222;
			rec_r[i][j] = 221;
			rec_m[i][j] = 223;
			org_m[i][j] = 225;
			
	end
end

end

			sao_stat_one_block sao_stat_one_block(
				.*
			/*	.rec_l(rec_l[i][j]), 
				.rec_r(rec_r[i][j]), 
				.rec_m(rec_m[i][j]), 
				.org_m(org_m[i][j]), 
				.sign_l(sign_l[i][j]), 
				.sign_r(sign_r[i][j]), 
				.diff(diff[i][j]) */
			);


endmodule