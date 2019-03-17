import rv32i_types::*;

module writeback #(parameter width = 32)
(
	 input [31:0] rdata_b,
	 input stage_regs regs_in,
	 output [31:0] rd_data,
	 output logic ld_regfile,
	 output [4:0] rd
);

logic [31:0] mask_out;
assign rd = regs_in.rd;
assign ld_regfile = regs_in.ctrl.load_regfile;

mem_mask mask
(
	.funct3(regs_in.funct3),
	.opcode(regs_in.ctrl.opcode),
	.mdrreg_out(rdata_b),
	.rs1_out(regs_in.rs1),
	.rs2_out(regs_in.rs2),
	.i_imm(regs_in.i_imm),
	.s_imm(regs_in.s_imm),
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
