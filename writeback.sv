import rv32i_types::*;

module writeback #(parameter width = 32)
(
	 input rv32i_word dcache_out,
	 input stage_regs regs_in,
	 output logic [31:0] rd_data,
	 output logic ld_regfile,
	 output logic [4:0] rd,
	 output stage_regs regs_out
);

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

endmodule : writeback
