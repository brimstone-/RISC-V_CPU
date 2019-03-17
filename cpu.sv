import rv32i_types::*;

module cpu
(
	input clk,

	// port A
	output logic read_a,
	output logic [31:0] address_a,
	input resp_a,
	input [31:0] rdata_a,
	
	// port B
	output logic read_b,
	output logic write,
	output logic [3:0] wmask,
	output logic [31:0] address_b,
	output logic [31:0] wdata,
	input resp_b,
	input [31:0] rdata_b
);

stage_regs stage_one_regs, stage_two_regs, stage_three_regs, stage_four_regs, stage_five_regs;

logic ld_regfile;
logic [4:0] rd;

rv32i_word rd_data;
rv32i_word pc;

fetch stage_one
(
    .clk, 
	 .read_a,
	 .address_a,
	 .resp_a,
	 .regs_in(stage_five_regs),
    .pc
);

decode stage_two
(
	.clk,
	.rdata_a, // from instruction cache
	.pc, // from fetch
	.cache_out(rd_data), // from wb
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
	.resp_b,
	.read_b,
	.write,
	.wmask,
	.address_b,
	.wdata,
	.regs_out(stage_four_regs)
);

writeback stage_five
(
	.rdata_b,
	.regs_in(stage_four_regs),
	.rd_data(rd_data),
	.ld_regfile(ld_regfile),
	.rd(rd),
	.regs_out(stage_five_regs)
);

endmodule : cpu
