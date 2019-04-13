import rv32i_types::*;

module forward_unit 
(
	input logic [4:0] rd, rs1_num, rs2_num,
	input rv32i_opcode opcode,
	input logic [31:0] rd_val,
	input logic load_regfile,
	output logic hazard [2],
	output logic [31:0] f
);

// rd from early instruction
// load_regfile from early instruction
// opcode from later instruction
// rs1_num from later instruction
// rs2_num from later instruction
// rd_val from early instruction

logic stored, valid_rs2, valid_rs1;
assign stored = (rd != 0) && (load_regfile == 1);
// will the value be stored in the regfile
assign valid_rs2 = (opcode == op_reg) || (opcode == op_br) || (opcode == op_store);
assign valid_rs1 = (opcode == op_imm) || (opcode == op_reg) || (opcode == op_jalr) || (opcode == op_br) || (opcode == op_load) || (opcode == op_store); 
// is rs2 actually being used
assign hazard[0] = (rs1_num == rd) && stored && valid_rs1;
assign hazard[1] = (rs2_num == rd) && stored && valid_rs2;

mux2 hazard_value 
(
	.sel(hazard[0] || hazard[1]),
	.a({32{1'bx}}),
	.b(rd_val),
	.f
);

endmodule : forward_unit