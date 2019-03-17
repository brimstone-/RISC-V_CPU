import rv32i_types::*;

module cpu
(
	input clk,

	// port A
	output read_a,
	output [31:0] address_a,
	input resp_a,
	input [31:0] rdata_a,
	
	// port B
	input read_b,
	input write,
	input [3:0] wmask,
	input [31:0] address_b,
	input [31:0] wdata,
	output logic resp_b,
	output logic [31:0] rdata_b
);

stage_regs stage_one_regs, stage_two_regs, stage_three_regs, stage_four_regs;

fetch stage_one
(
    .clk, 
	 .read_a,
	 .address_a,
	 .resp_a,
	 .regs_in(stage_five_regs),
    .regs_out(stage_one_regs)
);

decode stage_two
(
	.clk,
	.rdata_a, // from instruction cache
	.pc(stage_one_regs.pc), // from fetch
	.cache_out(data_out), // from wb
	.ld_regfile(ld_regfile), // from wb
	.rd(rd), // from wb
	.regs_out(stage_two_regs)
);

execute stage_three
(
	.clk,
	.regs_in(stage_two_regs),
	.regs_out(stage_three_regs)
);

mem stage_four
(
	.clk,
	.regs_in(stage_three_regs), 
	.regs_out(stage_four_regs)
);

writeback stage_five
(
	.rdata_b,
	.regs_in(stage_four_regs),
	.rd_data(rd_data),
	.ld_regfile(ld_regfile),
	.rd(rd)
);

endmodule : cpu
