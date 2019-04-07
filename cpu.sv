import rv32i_types::*;

module cpu
(
	input clk,

	// port A
	output logic read_a,
	output rv32i_word address_a,
	input resp_a,
	input rv32i_word rdata_a,
	
	// port B
	output logic read_b,
	output logic write,
	output logic [3:0] wmask,
	output rv32i_word address_b,
	output rv32i_word wdata,
	input resp_b,
	input rv32i_word rdata_b
);

stage_regs stage_one_regs, stage_two_regs, stage_three_regs, stage_four_regs, stage_five_regs;

logic ld_regfile;
logic [4:0] rd;
logic stall_three, stall_four;

rv32i_word rd_data;
rv32i_word pc;
rv32i_word instruction;
rv32i_word dcache_out;

fetch stage_one
(
    .clk, 
	 .read_a,
	 .rdata_a,
	 .address_a,
	 .resp_a,
	 .regs_in(stage_five_regs),
    .pc,
	 .instruction,
	 .stall_in(stall_four)
);

decode stage_two
(
	.clk,
	.reset(stage_four_regs.ctrl.pcmux_sel),
	.instruction, // from instruction cache
	.resp_a,
	.resp_b,
	.pc, // from fetch
	.cache_out(rd_data), // from wb
	.ld_regfile(ld_regfile), // from wb
	.rd(rd), // from wb
	.regs_out(stage_two_regs),
	.stall_in(stall_three)
);

execute stage_three
(
	.clk,
	.reset(stage_four_regs.ctrl.pcmux_sel),
	.resp_a,
	.resp_b,
	.regs_in(stage_two_regs),
	.regs_out(stage_three_regs),
	.stall_in(stall_four),
	.stall_out(stall_three)
);

mem stage_four
(
	.clk,
	.regs_in(stage_three_regs),
	.resp_a,
	.resp_b,
	.read_b,
	.rdata_b,
	.write,
	.wmask,
	.address_b,
	.wdata,
	.dcache_out,
	.regs_out(stage_four_regs),
	.stall_in(),
	.stall_out(stall_four)
);

writeback stage_five
(
	.regs_in(stage_four_regs),
	.rd_data(rd_data),
	.ld_regfile(ld_regfile),
	.rd(rd),
	.dcache_out,
	.regs_out(stage_five_regs)
);

endmodule : cpu
