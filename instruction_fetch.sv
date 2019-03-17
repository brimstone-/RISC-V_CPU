import rv32i_types::*;

module fetch (
    input logic clk, 
	 output read_a,
	 input resp_a,
	 output rv32i_word address_a,
    input stage_regs regs_in,
    output [31:0] pc
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
	.load(1'b1), 
	.in(pcmux_out),
	.out(pc_out)
);

pc_plus4 pc_plus4 (
	.in(pc_out), 
	.out(pc_plus4_out)
);

assign address_a = pc_out;
assign read_a = 1'b1;

register stage_reg (
	.clk(clk),
	.load(resp_a),
	.in(pc_out),
	.out(pc)
);

endmodule: fetch
