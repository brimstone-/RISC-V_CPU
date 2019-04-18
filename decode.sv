import rv32i_types::*;

module decode
(
	input clk,
	input reset,
	input [31:0] pc,
	input resp_a,
	input resp_b,
	input [31:0] cache_out,
	input logic ld_regfile,
	input [4:0] rd,
	input rv32i_word instruction,
	input predict_regs predict_regs_in,
	output predict_regs predict_regs_out,
	output stage_regs regs_out,
	output stage_regs regs_out_comb,
	
	input stall_in,
	
	input logic hazard_wb_dec [2],
	input logic [31:0] wb_dec
);

logic load_all;
logic [31:0] i,s,b,u,j;
logic [4:0] reg_rd, src_a, src_b;
logic [31:0] reg_a, reg_b;
rv32i_control_word ctrl;
rv32i_opcode ir_op;
logic [2:0] funct3;
logic [6:0] funct7;
stage_regs stage;

assign stage.i_imm 	= i;
assign stage.s_imm 	= s;
assign stage.b_imm 	= b;
assign stage.u_imm 	= u;
assign stage.j_imm 	= j;
assign stage.rd 		= reg_rd;
assign stage.rs1_num = src_a;
assign stage.rs2_num = src_b;
assign stage.pc		= pc;
assign stage.ctrl 	= ctrl;
assign stage.valid 	= 1;
assign stage.alu 		= 32'bz;
assign stage.br		= 32'bz;
assign stage.funct3 	= funct3;

assign regs_out_comb = stage;

mux2 rs1_mux
(
	.sel(hazard_wb_dec[0]),
	.a(reg_a),
	.b(wb_dec),
	.f(stage.rs1)
);

mux2 rs2_mux
(
	.sel(hazard_wb_dec[1]),
	.a(reg_b),
	.b(wb_dec),
	.f(stage.rs2)
);

ir IR
(
	 .in(instruction),					// comes from CACHE of stage 1
    .funct3(funct3),						// goes to control ROM
    .funct7(funct7),						// goes to control ROM
    .opcode(ir_op),						// goes to control ROM
    .i_imm(i),								// goes to stage 3
    .s_imm(s),								// goes to stage 3
    .b_imm(b),								// goes to stage 3
    .u_imm(u),								// goes to stage 3
    .j_imm(j),								// goes to stage 3
    .rs1(src_a),							// goes to regfile
    .rs2(src_b),							// goes to regfile
    .rd(reg_rd)							// goes to stage 3
);

control_rom ROM
(
    .opcode(ir_op),
	 .s_imm(s),
    .funct3(funct3),
	 .funct7(funct7),
	 .ctrl(ctrl)
);

regfile regfile
(
	 .clk(clk),
	 .load(ld_regfile),					// comes from ROM of WB
	 .in(cache_out),						// comes from CACHE of WB		
	 .src_a(src_a),						// comes from IR 
	 .src_b(src_b), 						// comes from IR
	 .dest(rd),								// comes from stage 5
	 .reg_a(reg_a),						// goes to stage 3
	 .reg_b(reg_b)							// goes to stage 3
);

register #($bits(stage)) stage_reg
(
	 .clk(clk),
    .load(resp_a && resp_b),
	 .reset(reset || (stall_in && (resp_b) &&(resp_a))),
    .in(stage),							// struct of things to pass to stage 3
    .out(regs_out)						// values stage 3 holds
);

register #($bits(predict_regs_in)) bhr_reg
(
	.clk,
	.load(resp_a && resp_b),
	.reset(reset && resp_a && resp_b),
	.in(predict_regs_in),
	.out(predict_regs_out)
);

endmodule : decode
