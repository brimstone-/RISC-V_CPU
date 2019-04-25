import rv32i_types::*;

module writeback #(parameter width = 32)
(
	 input clk,
	 input rv32i_word dcache_out,
	 input stage_regs regs_in,
	 output logic [31:0] rd_data,
	 output logic ld_regfile,
	 output logic [4:0] rd,
	 output stage_regs regs_out,
	 input logic stall
);

logic [31:0] instr_count_out;

logic [31:0] mask_out;
assign rd = regs_in.rd;
assign ld_regfile = regs_in.ctrl.load_regfile;

assign regs_out = regs_in;

load_mask load_mask
(
	.in(dcache_out),
	.load_type(regs_in.ctrl.load_type),
	.load_unsigned(regs_in.ctrl.load_unsigned),
	.alu_out(regs_in.alu[1:0]),
	.out(mask_out)
);

mux8 regfilemux
(
	.sel(regs_in.ctrl.regfilemux_sel),
	.a(regs_in.alu),
	.b(regs_in.br),
	.c(regs_in.u_imm),
	.d(mask_out), // from rom
	.e(regs_in.pc + 4),
	.f(),
	.g(),
	.h(),
	.out(rd_data)
);

register #(.width(32)) instruction_counter
(
	.clk,
	.load(regs_in.valid & ~stall),
	.reset(1'b0),
	.in(instr_count_out + 1),
	.out(instr_count_out)
);

endmodule : writeback
