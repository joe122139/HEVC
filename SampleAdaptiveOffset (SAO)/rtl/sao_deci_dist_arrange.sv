`timescale 1ns/1ps
module sao_deci_dist_arrange #(
	parameter num_pix_CTU_log2 = 5,
	parameter diff_clip_bit = 4,
	parameter state_len = 6,
	parameter n_category = 4,
	parameter n_category_bo = 8,
	parameter n_eo_type = 4,
	parameter n_sao_type = 3,
	parameter dist_len = 21,
	parameter SHIFT = 24,
	parameter num_accu_len = num_pix_CTU_log2*2-1,
	parameter total_offset = n_category*n_eo_type+n_category_bo
)
(
	input	logic 	signed [num_accu_len+diff_clip_bit:0]							sum_blk_CTU_DCI[0:n_eo_type-1][0:n_category-1],
	input	logic 			[num_accu_len:0]									num_blk_CTU_DCI[0:n_category-1][0:n_category-1],
	input	logic 	signed [num_accu_len+diff_clip_bit:0]							sum_blk_CTU_bo_DCI[0:n_category_bo-1],
	input 	logic 			[num_accu_len:0]									num_blk_CTU_bo_DCI[0:n_category_bo-1],
	input   logic			[state_len-1:0]												cnt_dc,
	input   logic																		isWorking_deci,
	input	logic			[4:0]														cand_bo,
	
	//merge


	input	logic			[n_sao_type-1:0]											L_merge_sao_type,
	input	logic			[1:0]														L_merge_sao_mode,	
	input	logic			[n_sao_type-1:0]											U_merge_sao_type,
	input	logic			[1:0]														U_merge_sao_mode,
	input	logic			[$clog2(32)-1:0]									L_typeAuxInfo,	
	input	logic			[$clog2(32)-1:0]									U_typeAuxInfo,
	
	//input   logic			[2:0]														state_dc,
	output 	logic 			[num_accu_len:0]						num_blk_CTU,
	output 	logic 	signed 	[num_accu_len+diff_clip_bit:0] 						sum_blk_CTU
);


	logic			[n_sao_type-1:0]													merge_sao_type;
	logic			[2:0]																merge_sao_mode;
	logic			[$clog2(32)-1:0]											typeAuxInfo;
	
	
	logic		signed	[2:0]															delta;
	logic		signed	[3:0]															idx;
	logic		isWithinLimit;
	
assign isWithinLimit = (typeAuxInfo <= cand_bo+1) && (typeAuxInfo >=cand_bo -3);
always_comb begin
	sum_blk_CTU = 0;
	num_blk_CTU = 0;
	merge_sao_type = 0;
	typeAuxInfo = 0;
	merge_sao_mode = 0;
	delta = 0;
	idx = 0;
	if(isWorking_deci) begin
		// 48 -- 51: merge left
		if(cnt_dc>47-SHIFT && cnt_dc<52-SHIFT)	begin	//[24,27]
			merge_sao_mode = L_merge_sao_mode;
			merge_sao_type = L_merge_sao_type;
			typeAuxInfo = L_typeAuxInfo;
		end
		else if(cnt_dc<56-SHIFT)	begin		//[28,31]
			merge_sao_mode = U_merge_sao_mode;
			merge_sao_type = U_merge_sao_type;
			typeAuxInfo = U_typeAuxInfo;
		end
	
		if (isWithinLimit) begin
			delta = $signed({1'b0,typeAuxInfo}) - $signed({1'b0,cand_bo});
			idx = $signed({1'b0,2'd3}) + delta + $signed({1'b0,cnt_dc%4});
		end
		if (cnt_dc <16)	begin
			sum_blk_CTU = sum_blk_CTU_DCI[(cnt_dc>>2)][(cnt_dc%4)];
			num_blk_CTU = num_blk_CTU_DCI[(cnt_dc>>2)][(cnt_dc%4)];
			
			end
		else if(cnt_dc<48-SHIFT)	begin	//16-23
			sum_blk_CTU = sum_blk_CTU_bo_DCI[cnt_dc-16];
			num_blk_CTU = num_blk_CTU_bo_DCI[cnt_dc-16];
			end
		
		// 52 -- 55: merge left
		else if(cnt_dc<56-SHIFT ) begin		//24-31
			if(merge_sao_mode && merge_sao_type<4)		begin
				sum_blk_CTU = sum_blk_CTU_DCI[merge_sao_type][(cnt_dc%4)];
				num_blk_CTU = num_blk_CTU_DCI[merge_sao_type][(cnt_dc%4)];
			end
			if(merge_sao_mode && merge_sao_type==4)	begin			//when merge_sao_type ==4 and typeAuxInfo is near cand_bo, it is used, or it is not used.
				if(isWithinLimit)	begin
					sum_blk_CTU = sum_blk_CTU_bo_DCI[idx[2:0]];
					num_blk_CTU = num_blk_CTU_bo_DCI[idx[2:0]];
				end
			end
			
		end


	end
		

	
end
endmodule