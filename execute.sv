import rv32i_types::*;

module execute #(parameter width = 32)
(
	input clk,
	input reset,
	input resp_a,
	input resp_b,
	input stage_regs regs_in,
	output stage_regs regs_out,
	
	input stall_in,
	output logic stall_out
);

rv32i_word alumux1_out, alumux2_out;
rv32i_word cmpmux_out;
rv32i_control_word ctrl_in;

stage_regs regs;

logic br_en;
logic [31:0] alu_out;

// ALU
mux2 alumux1
(
	.sel(regs_in.ctrl.alumux1_sel),
	.a(regs_in.rs1),
	.b(regs_in.pc),
	.f(alumux1_out)
);

mux8 alumux2
(
	.sel(regs_in.ctrl.alumux2_sel),
	.a(regs_in.i_imm),
	.b(regs_in.u_imm),
	.c(regs_in.b_imm),
	.d(regs_in.s_imm),
	.e(regs_in.rs2),
	.f(regs_in.j_imm),
	.g(),
	.h(),
	.out(alumux2_out)
);

alu alu
(
	.aluop(regs_in.ctrl.aluop),
	.a(alumux1_out),
	.b(alumux2_out),
	.f(alu_out)
);

// CMP
mux2 cmpmux
(
	.sel(regs_in.ctrl.cmpmux_sel),
	.a(regs_in.rs2),
	.b(regs_in.i_imm),
	.f(cmpmux_out)
);

cmp cmp_module
(
	.cmpop(regs_in.ctrl.cmpop),
	.a(regs_in.rs1),
	.b(cmpmux_out),
	.br_en(br_en)
);

// stage_regs value passing
assign regs.i_imm = regs_in.i_imm;
assign regs.s_imm = regs_in.s_imm;
assign regs.b_imm = regs_in.b_imm;
assign regs.u_imm = regs_in.u_imm;
assign regs.j_imm = regs_in.j_imm;
assign regs.rd = regs_in.rd;
assign regs.rs1 = regs_in.rs1;
assign regs.rs2 = regs_in.rs2;
assign regs.alu = alu_out;
assign regs.pc = alu_out;
assign ctrl_in.opcode = regs_in.ctrl.opcode;
assign ctrl_in.aluop = regs_in.ctrl.aluop;
assign ctrl_in.regfilemux_sel = regs_in.ctrl.regfilemux_sel;
assign ctrl_in.load_regfile = regs_in.ctrl.load_regfile;
assign ctrl_in.cmpop = regs_in.ctrl.cmpop;
assign ctrl_in.mem_byte_enable = regs_in.ctrl.mem_byte_enable;
assign ctrl_in.write = regs_in.ctrl.write;
assign ctrl_in.read_b = regs_in.ctrl.read_b;
assign ctrl_in.pcmux_sel = (br_en && (regs_in.ctrl.opcode == op_br)) || (regs_in.ctrl.pcmux_sel && (regs_in.ctrl.opcode == op_jal)) || (regs_in.ctrl.pcmux_sel && (regs_in.ctrl.opcode == op_jalr));
assign ctrl_in.alumux1_sel = regs_in.ctrl.alumux1_sel;
assign ctrl_in.alumux2_sel = regs_in.ctrl.alumux2_sel;
assign ctrl_in.cmpmux_sel = regs_in.ctrl.cmpmux_sel;
assign ctrl_in.store_type = regs_in.ctrl.store_type;
assign ctrl_in.load_type = regs_in.ctrl.load_type;
assign ctrl_in.load_unsigned = regs_in.ctrl.load_unsigned;
assign regs.ctrl = ctrl_in;
assign regs.br = {{31{1'b0}},br_en};
assign regs.valid = regs_in.valid;
assign regs.funct3 = regs_in.funct3;

assign stall_out = stall_in;

register #($bits(regs)) stage_reg
(
	 .clk(clk),
    .load(resp_a && resp_b), 					// always high for now. will be dependedent on mem_resp later
	 .reset(reset),
    .in(regs),						// struct of things to pass to stage 4
    .out(regs_out)						// values stage 3 holds
);

endmodule : execute
