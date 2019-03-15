import rv32i_types::*;

module execute #(parameter width = 32)
(
	input clk,
	input stage_regs in,
	output stage_regs regs
);

rv32i_word alumux1_out, alumux2_out;
rv32i_word cmpmux_out;

stage_regs out;

logic br_en;

// ALU
mux2 alumux1
(
	.sel(in.ctrl.alumux1_sel),
	.a(in.rs1),
	.b(in.pc),
	.f(alumux1_out)
);

mux8 alumux2
(
	.sel(in.ctrl.alumux2_sel),
	.a(in.i_imm),
	.b(in.u_imm),
	.c(in.b_imm),
	.d(in.s_imm),
	.e(in.rs2),
	.f(in.j_imm),
	.g(),
	.h(),
	.out(alumux2_out)
);

alu alu
(
	.aluop(in.ctrl.aluop),
	.a(alumux1_out),
	.b(alumux2_out),
	.f(out.alu)
);

// CMP
mux2 cmpmux
(
	.sel(in.ctrl.cmpmux_sel),
	.a(in.rs2),
	.b(in.i_imm),
	.f(cmpmux_out)
);

cmp cmp_module
(
	.cmpop(in.ctrl.cmpop),
	.a(in.rs1),
	.b(cmpmux_out),
	.br_en(br_en)
);

// stage_regs value passing
assign out.i_imm = in.i_imm;
assign out.s_imm = in.s_imm;
assign out.b_imm = in.b_imm;
assign out.u_imm = in.u_imm;
assign out.j_imm = in.j_imm;
assign out.rd = in.rd;
assign out.rs1 = in.rs1;
assign out.rs2 = in.rs2;
assign out.pc = out.alu;
assign out.ctrl = in.ctrl;
assign out.br = {{31{1'b0}},br_en};
assign out.valid = in.valid;

register #($bits(out)) stage_reg
(
	 .clk(clk),
    .load(1'b1), 					// always high for now. will be dependedent on mem_resp later
    .in(out),							// struct of things to pass to stage 3
    .out(regs)								// values stage 3 holds
);

endmodule : execute
