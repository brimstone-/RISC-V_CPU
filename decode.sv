import rv32i_types::*;

module decode
(
	 input [31:0] reg_in,
    input [31:0] pc,
    input logic ld_regfile,
    input [4:0] rd,
	 input clk,
	 output stage_regs regs
	 
);

logic load_all;
logic [31:0] i,s,b,u,j;
logic [4:0] reg_rd, reg_a, reg_b, src_a, src_b;
rv32i_control_word ctrl;
rv32i_opcode ir_op;
logic [2:0] funct3;
logic [6:0] funct7;
stage_regs stage;

assign load_all 		= 1;
assign stage.i_imm 	= i;
assign stage.s_imm 	= s;
assign stage.b_imm 	= b;
assign stage.u_imm 	= u;
assign stage.j_imm 	= j;
assign stage.rd 		= reg_rd;
assign stage.rs1 	= reg_a;
assign stage.rs2 	= reg_b;
assign stage.pc		= pc;
assign stage.ctrl 	= ctrl;
assign stage.valid 	= 1;

ir IR
(
	 .in(reg_in),							// comes from CACHE of stage 1
    .funct3(funct3),						// goes to control ROM
    .funct7(funct7),						// goes to control ROM
    .opcode(ir_op),						// goes to control ROM
    .i_imm(i),								// goes to stage 3
    .s_imm(s),								// goes to stage 3
    .b_imm(b),								// goes to stage 3
    .u_imm(u),								// goes to stage 3
    .j_imm(j),								// goes to stage 3
    .rs1(reg_a),							// goes to regfile
    .rs2(reg_b),							// goes to regfile
    .rd(reg_rd)							// goes to stage 3
);

control_rom ROM
(
    .opcode(ir_op),
    .funct3(funct3),
	 .funct7(funct7),
	 .ctrl(ctrl)
);

regfile regfile
(
	 .clk(clk),
	 .load(ld_regfile),					// comes from ROM of WB
	 .in(reg_in),							// comes from CACHE of WB		
	 .src_a(src_a),						// comes from IR 
	 .src_b(src_b), 						// comes from IR
	 .dest(rd),								// comes from stage 5
	 .reg_a(reg_a),						// goes to stage 3
	 .reg_b(reg_b)							// goes to stage 3
);

register #($bits(reg_in)) stage_reg
(
	 .clk(clk),
    .load(load_all), 					// always high for now. will be dependedent on mem_resp later
    .in(reg_in),							// struct of things to pass to stage 3
    .out(regs)								// values stage 3 holds
);




endmodule : decode