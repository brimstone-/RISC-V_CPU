import rv32i_types::*;

module execute #(parameter width = 32)
(
	input clk,
	input load,
	input rv32i_word pc_in,
	input rv32i_word rs1_in, rs2_in,
	input [2:0] funct3,
	input [6:0] funct7,
	input rv32i_word b_imm, i_imm, j_imm, s_imm, u_imm,
	input alu_ops aluop,
	input cmp_ops cmpop,
	output logic [width-1:0] out
);

// PC
mux2 pc_mux
(
	.sel(pcmux_sel),
	.a(i_imm),
	.b(s_imm),
	.f(pc_mux_out);
);

assign pc_addr_out = pc_in + pc_mux_out;

register pc_reg
(
	.clk,
	.load(1b'1),
	.in(pc_addr_out),
	.out(pc_reg_out)
);

// ALU
mux2 alumux1
(
	.sel(alumux1_sel),
	.a(rs1_in),
	.b(pc_in),
	.f(alumux1_out)
);

mux8 alumux2
(
	.sel(alumux2_sel),
	.a(b_imm),
	.b(i_imm),
	.c(j_imm),
	.d(s_imm),
	.e(u_imm),
	.f(rs2_in),
	.g(),
	.h(),
	.out(alumux2_out)
);

alu alu
(
	.aluop(aluop),
	.a(alumux1_out),
	.b(alumux2_out),
	.f(alu_out)
);

register alu_reg
(
	.clk,
	.load(1b'1),
	.in(alu_out),
	.out(alu_reg_out)
);

// CMP
cmp cmp_module
(
	.cmpop(cmpop),
	.a(rs1_in),
	.b(cmpmux_out),
	.br_en(br_en)
);

mux2 cmpmux
(
	.sel(cmpmux_sel),
	.a(rs2_in),
	.b(i_imm),
	.f(cmpmux_out)
);

register br_reg
(
	.clk,
	.load(1b'1),
	.in(br_en),
	.out(br_reg_out)
);

// Passed Values
register rd_reg
(
	.clk,
	.load(1b'1),
	.in(rd_in),
	.out(rd_out)
);

register control_reg
(
	.clk,
	.load(1b'1),
	.in(crtl_in),
	.out(crtl_out)
);

endmodule : execute
