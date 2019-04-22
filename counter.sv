import rv32i_types::*;

module counter
(
   input rv32i_word mem_addr,
	input mem_read, mem_write,
	output logic read_b_counter,
	output logic write_counter,
	output logic mem_resp,
	input rv32i_word mem_rdata_in,
	output rv32i_word mem_rdata_out,

   input rv32i_word icache_hit_count,
   input rv32i_word icache_miss_count,
   input rv32i_word dcache_hit_count,
   input rv32i_word dcache_miss_count,
   input rv32i_word l2_hit_count,
   input rv32i_word l2_miss_count,
   input rv32i_word ewb_writes_count,
	input rv32i_word branch_total_count,
   input rv32i_word branch_correct_count,
   input rv32i_word branch_incorrect_count,
   input rv32i_word prefetch_hit_count,
   input rv32i_word prefetch_read_count,

   output logic icache_hit_reset,
   output logic icache_miss_reset,
	output logic dcache_hit_reset,
	output logic dcache_miss_reset,
   output logic l2_hit_reset,
   output logic l2_miss_reset,
   output logic ewb_writes_reset,
   output logic branch_total_reset,
   output logic branch_correct_reset,
   output logic branch_incorrect_reset,
   output logic prefetch_hit_reset,
   output logic prefetch_read_reset
);

logic addr_hit;
counter_addr tag;
rv32i_word mem_rdata;

assign tag = counter_addr'(mem_addr[7:0]);

assign addr_hit = ((tag == icache_hit)
                | (tag == icache_miss)
                | (tag == dcache_hit)
                | (tag == dcache_miss)
                | (tag == l2_hit)
                | (tag == l2_miss)
                | (tag == ewb_writes)
                | (tag == branch_total)
                | (tag == branch_correct)
                | (tag == branch_incorrect)
                | (tag == prefetch_hit)
                | (tag == prefetch_read))
					 & (mem_addr[31:8] == 24'h000000);

assign mem_rdata_out = mem_rdata;
assign read_b_counter = mem_read & ~addr_hit;
assign write_counter = mem_write & ~addr_hit;

always_comb
begin
	mem_resp = 0;
	mem_rdata = mem_rdata_in;
	icache_hit_reset = 0;
	icache_miss_reset = 0;
	dcache_hit_reset = 0;
	dcache_miss_reset = 0;
	l2_hit_reset = 0;
	l2_miss_reset = 0;
	ewb_writes_reset = 0;
	branch_total_reset = 0;
	branch_correct_reset = 0;
	branch_incorrect_reset = 0;
	prefetch_hit_reset = 0;
	prefetch_read_reset = 0;

	if (mem_read & addr_hit) begin
		mem_resp = 1;
		case (tag)
			icache_hit       : mem_rdata = icache_hit_count;
			icache_miss      : mem_rdata = icache_miss_count;
			dcache_hit       : mem_rdata = dcache_hit_count;
			dcache_miss      : mem_rdata = dcache_miss_count;
			l2_hit           : mem_rdata = l2_hit_count;
			l2_miss          : mem_rdata = l2_miss_count;
			ewb_writes       : mem_rdata = ewb_writes_count;
			branch_total     : mem_rdata = branch_total_count;
			branch_correct   : mem_rdata = branch_correct_count;
			branch_incorrect : mem_rdata = branch_incorrect_count;
			prefetch_hit     : mem_rdata = prefetch_hit_count;
			prefetch_read    : mem_rdata = prefetch_read_count;
		endcase
	end
	else if (mem_write & addr_hit) begin
		mem_resp = 1;
		case (tag)
			icache_hit       : icache_hit_reset = 1;
			icache_miss      : icache_miss_reset = 1;
			dcache_hit       : dcache_hit_reset = 1;
			dcache_miss      : dcache_miss_reset = 1;
			l2_hit           : l2_hit_reset = 1;
			l2_miss          : l2_miss_reset = 1;
			ewb_writes       : ewb_writes_reset = 1;
			branch_total     : branch_total_reset = 1;
			branch_correct   : branch_correct_reset = 1;
			branch_incorrect : branch_incorrect_reset = 1;
			prefetch_hit     : prefetch_hit_reset = 1;
			prefetch_read    : prefetch_read_reset = 1;
		endcase
	end
end

endmodule : counter