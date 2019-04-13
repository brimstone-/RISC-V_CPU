import rv32i_types::*;

module forward
(
	input stage_regs de, exe, mem, wb,
	input logic [31:0] cache_data,
	output logic hazard_wb_mem [2],
	output logic hazard_wb_exec [2],
	output logic hazard_wb_dec [2],
	output logic hazard_mem_exec [2],
	output logic hazard_exe_dec [2],
	output [31:0] wb_mem, wb_exec, wb_dec, mem_exec
);
 
// WB -> MEM
// REGISTER VALUE
forward_unit wb_to_mem
(
	.rd(wb.rd),
	.rd_val(cache_data),
	.rs1_num(mem.rs1_num),
	.rs2_num(mem.rs2_num),
	.opcode(mem.ctrl.opcode),
	.load_regfile(wb.ctrl.load_regfile),
	.hazard(hazard_wb_mem),
	.f(wb_mem)
);

// WB -> EXEC
// REGISTER VALUE
forward_unit wb_to_exec
(
	.rd(wb.rd),
	.rd_val(cache_data),
	.rs1_num(exe.rs1_num),
	.rs2_num(exe.rs2_num),
	.opcode(exe.ctrl.opcode),
	.load_regfile(wb.ctrl.load_regfile),
	.hazard(hazard_wb_exec),
	.f(wb_exec)
);

// WB -> DEC
// REGISTER VALUE
forward_unit wb_to_dec
(
	.rd(wb.rd),
	.rd_val(cache_data),
	.rs1_num(de.rs1_num),
	.rs2_num(de.rs2_num),
	.opcode(de.ctrl.opcode),
	.load_regfile(wb.ctrl.load_regfile),
	.hazard(hazard_wb_dec),
	.f(wb_dec)
);

// MEM -> EXEC
// ADDRESS
forward_unit mem_to_exec
(
	.rd(mem.rd),
	.rd_val(mem.alu),
	.rs1_num(exe.rs1_num),
	.rs2_num(exe.rs2_num),
	.opcode(exe.ctrl.opcode),
	.load_regfile(mem.ctrl.load_regfile),
	.hazard(hazard_mem_exec),
	.f(mem_exec)
);

// EXEC -> DEC
// used to check the special stalling condition
forward_unit exec_to_dec
(
	.rd(exe.rd),
	.rd_val(), // leave empty, don't need to forward anything
	.rs1_num(de.rs1_num), 
	.rs2_num(de.rs2_num),
	.opcode(de.ctrl.opcode),
	.load_regfile(exe.ctrl.load_regfile),
	.hazard(hazard_exe_dec),
	.f() // leave empty, don't need to forward anything
);




endmodule : forward
