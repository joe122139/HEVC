interface  sao_if();
parameter bit_depth = 8;
parameter diff_clip_bit = 4;
parameter n_pix = 4;
parameter pic_width_len = 13;
parameter pic_height_len = 13;
parameter blk_22_X_len = 6;
parameter blk_22_Y_len = 6;
parameter cnt_st_len = 10;
parameter cnt_dc_len = 6;
parameter isChroma  = 0;
parameter cut_x_len = 9;
parameter cut_y_len = 9;
parameter num_pix_CTU_log2 = 5;
parameter n_category = 4;
parameter n_category_bo = 8;
parameter n_eo_type = 4;
parameter sao_type_len = 3;
parameter offset_len = 4;
parameter num_accu_len = num_pix_CTU_log2*2-1;


logic 	[pic_width_len-1:0]				pic_width;			
logic 	[pic_height_len-1:0]			pic_height;

logic	[blk_22_X_len-1:0]				X_;
logic	[blk_22_X_len-1:0]				Y_;
logic 									en_i,en_o,en_o_2;

logic 	[cut_x_len-1:0]					ctu_x;
logic 	[cut_y_len-1:0]					ctu_y;
logic   [2:0]							ctb_size_log2;
logic 	[bit_depth-1:0] 				n_rec_l[0:n_pix-1];
logic 	[bit_depth-1:0] 				n_rec_r[0:n_pix-1];
logic 	[bit_depth-1:0] 				n_rec_m[0:n_pix-1];
logic 	[bit_depth-1:0] 				n_org_m[0:n_pix-1];	
logic 	[bit_depth-1:0] 				rec_in[0:n_pix-1][0:n_pix-1];
logic	[2:0]							ctu_size;


logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU[0:n_eo_type-1][0:n_category-1];
logic 	[num_accu_len:0]										num_blk_CTU[0:n_eo_type-1][0:n_category-1];

logic signed [num_accu_len+diff_clip_bit:0]						sum_blk_CTU_bo[0:n_category_bo-1];
logic 	[num_accu_len:0]										num_blk_CTU_bo[0:n_category_bo-1];

logic   [8:0]							lamda[0:2];

logic 			[sao_type_len-1:0]										sao_type[0:1];
logic 	signed	[offset_len-1:0]										offset[0:n_category-1];
logic 			[1:0]    												sao_mode[0:1];					//0£º OFF    1:NEW   2:MERGE
logic 			[$clog2(32)-1:0]   										typeAuxInfo[0:2];

endinterface              