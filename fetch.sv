import rv32i_types::*;

module fetch (
    input clk, 
	 output logic read_a,
	 input [31:0] rdata_a,
	 input resp_a,
	 input resp_b,
	 input read_b,
	 input write,
	 output rv32i_word address_a,
    input stage_regs regs_in,
    output rv32i_word pc,
	 output rv32i_word instruction,
	 input stall_in
);

stage_regs regs_out;
rv32i_word pcmux_out;
rv32i_word pc_out;

logic [31:0] pc_plus4_out;

mux2 pc_mux (
	.sel(regs_in.ctrl.pcmux_sel),
	.a(pc_plus4_out),
	.b(regs_in.pc),
	.f(pcmux_out)
);

pc_register pc_reg (
	.clk(clk),
	.load(stall_in), 
	.in(pcmux_out),
	.out(pc_out)
);


assign pc_plus4_out = pc_out + 4;


assign address_a = pc_out;
assign read_a = 1'b1;

register stage_reg (
	.clk(clk),
	.load(stall_in),
	.in(pc_out),
	.out(pc)
);

register rdata (
	.clk,
	.load(stall_in),
	.in(rdata_a),
	.out(instruction)
);

endmodule: fetch