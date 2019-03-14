import rv32i_types::*;

module execute #(parameter width = 32)
(
	input clk,
	input load,
	input [width-1:0] pc_in,
	input [2:0] funct3,
	input [6:0] funct7,
	input rv32i_word i_imm, j_imm, s_imm, u_imm,
	input alu_ops aluop,
	output logic [width-1:0] out
);

logic [width-1:0] data;

/* Altera device registers are 0 at power on. Specify this
 * so that Modelsim works as expected.
 */
initial
begin
	data = 1'b0;
end

always_ff @(posedge clk)
begin
	if (load)
	begin
		data = in;
	end
end

always_comb
begin
	out = data;
end

// PC
mux2 pc_mux
(
	.sel(pc_mux_sel),
	.a(i_imm),
	.b(s_imm),
	.f()
);

register pc_reg
(
	.clk,
	.load(1b'1),
	.in(pc_addr_out),
	.out(pc_reg_out)
);

// ALU
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

endmodule : execute
