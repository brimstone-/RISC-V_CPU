import rv32i_types::*;

module forward_unit
(
	input stage_regs decode_regs,
	input stage_regs exec_regs,
	input stage_regs mem_regs,
	
	output logic ex_fetch_haz,
	output logic ex_dec_haz [3],
	output logic mem_dec_haz [2],
	output logic mem_ex_haz [2],
	
	input rv32i_word alu_out, // exec_regs val
	input rv32i_word rdata_b, // mem_regs val
	
	output rv32i_word exec_forward,
	output rv32i_word mem_forward
);

// branch hazards
assign ex_fetch_haz   = decode_regs.ctrl.opcode == op_br;

// exec -> decode
assign ex_dec_haz[1]  = (decode_regs.rs2_num == exec_regs.rd) & (exec_regs.ctrl.load_regfile == 1) & (exec_regs.rd != 0);
assign ex_dec_haz[0]  = (decode_regs.rs1_num == exec_regs.rd) & (exec_regs.ctrl.load_regfile == 1) & (exec_regs.rd != 0) & 
									~((decode_regs.ctrl.opcode == op_store) & (exec_regs.ctrl.opcode == op_load));

// exec -> decode special situation	
assign ex_dec_haz[2]  = (decode_regs.rs1_num == exec_regs.rd) & (exec_regs.ctrl.opcode == op_load) & (exec_regs.rd != 0);
//assign ex_dec_haz[3]  = 

// mem -> decode
assign mem_dec_haz[0] = (decode_regs.rs1_num == mem_regs.rd) & (mem_regs.ctrl.load_regfile == 1) & (mem_regs.rd  != 0);
assign mem_dec_haz[1] = (decode_regs.rs2_num == mem_regs.rd) & (mem_regs.ctrl.load_regfile == 1) & (mem_regs.rd  != 0);

// mem -> exec **
assign mem_ex_haz[0]  = (exec_regs.rs1_num == mem_regs.rd) & (mem_regs.ctrl.load_regfile == 1) & (mem_regs.rd  != 0);
assign mem_ex_haz[1]  = (exec_regs.rs2_num == mem_regs.rd) & (mem_regs.ctrl.load_regfile == 1) & (mem_regs.rd  != 0);

//// writeback -> decode **
//assign wb_dec_haz[0]  = decode_regs.rs1_num == wb_regs.rd;
//assign wb_dec_haz[1]  = decode_regs.rs2_num == wb_regs.rd;
//
//// writeback -> exec **
//assign wb_ex_haz[0]  = (exec_regs.rs1_num == exec_regs.rd) & (wb_regs.ctrl.load_regfile == 1) & (wb_regs.rd  != 0);
//assign wb_ex_haz[1]  = (exec_regs.rs2_num == exec_regs.rd) & (wb_regs.ctrl.load_regfile == 1) & (wb_regs.rd  != 0);

// precedence


mux2 exec_forward_mux
(
	.sel(ex_dec_haz[0] | ex_fetch_haz),
	.a(exec_regs.rs1),
	.b(alu_out),
	.f(exec_forward)
);

assign mem_forward = mem_ex_haz[0] ? mem_regs.alu : rdata_b;

endmodule : forward_unit
