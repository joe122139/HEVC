module test_sao_stat_one_block;
parameter bit_depth = 8;
parameter diff_clip_bit = 4;
parameter           CK = 10.0;

typedef  logic [bit_depth-1:0] sample;
typedef  logic [bit_depth:0] sign_sample;
sample 				rec_l[0:3][0:3];
sample 				rec_r[0:3][0:3];
sample 				rec_m[0:3][0:3];
sample 				org_m[0:3][0:3];
 logic signed [1:0] 	sign_l[0:3][0:3];
 logic signed [1:0] 	sign_r[0:3][0:3];
 logic signed [4:0]	diff[0:3][0:3];
// logic signed [diff_clip_bit+4:0]	sum;
 logic signed [diff_clip_bit+4:0]	sum_blk;
 logic signed [3:0]	num_blk;
  bit clk;
initial begin

for(int i=0;i<4;i++) begin
	for(int j=0;j<4;j++) begin
			rec_l[i][j] = 0;
			rec_r[i][j] = 0;
			rec_m[i][j] = 0;
			org_m[i][j] = 0;
			
	end
end

end

			sao_stat_one_block #(.diff_clip_bit(diff_clip_bit))sao_stat_one_block(
				sao_if.BLK
			/*	.rec_l(rec_l[i][j]), 
				.rec_r(rec_r[i][j]), 
				.rec_m(rec_m[i][j]), 
				.org_m(org_m[i][j]), 
				.sign_l(sign_l[i][j]), 
				.sign_r(sign_r[i][j]), 
				.diff(diff[i][j]) */
			);
initial begin
  clk = 0; #(CK/2.0) forever #(CK/2.0) clk = ~clk;
end

initial begin
	forever @ (posedge clk) begin
		for(int i=0;i<4;i++) begin
			for(int j=0;j<4;j++) begin
					rec_m[i][j] = {$random}%255;
					org_m[i][j] = {$random}%255;
			end
		end

		#1 $display("%d,%d,%d\n", org_m[0][0], rec_m[0][0], sao_stat_one_block.sum);
 
 end
 end

endmodule