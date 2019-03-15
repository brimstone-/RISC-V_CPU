import rv32i_types::*;

module writeback #(parameter width = 32)
(
	 input [31:0] in,
	 input stage_regs stage,
	 output [31:0] out,
	 output logic ld_regfile,
	 output [4:0] rd
);

logic [31:0] mask_out;
assign rd = stage.rd;
assign ld_regfile = stage.ctrl.load_regfile;

mem_mask mask
(
	.funct3(stage.funct3),
	.opcode(stage.ctrl.opcode),
	.mdrreg_out(in),
	.rs1_out(stage.rs1),
	.rs2_out(stage.rs2),
	.i_imm(stage.i_imm),
	.s_imm(stage.s_imm),
	.out(mask_out)
);

mux8 regfilemux
(
	.sel(stage.ctrl.regfilemux_sel),
	.a(stage.alu),
	.b(stage.br),
	.c(stage.u_imm),
	.d(mask_out), // from rom
	.e(stage.pc + 4),
	.f(),
	.g(),
	.h(),
	.out(out)
);

endmodule : writeback
