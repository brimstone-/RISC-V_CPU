import rv32i_types::*;

module fetch (
    input logic clk, 
	 output read_a,
	 input resp_a,
	 output rv32i_word address_a,
    input stage_regs regs_in,
    output stage_regs regs_out
); 

stage_regs out, regs_out;
rv32i_word pcmux_out;
rv32i_word pc_out;

mux2 pc_mux (
	.sel(regs_in.ctrl.pcmux_sel),
	.a(pc_plus4_out),
	.b(regs_in.pc),
	.f(pcmux_out)
);

pc_register pc (
	.clk(clk),
	.load(1'b1), 
	.in(pcmux_out),
	.out(pc_out), 
);

pc_plus4 pc_plus4 (
	.in(pc_out), 
	.out(pc_plus4_out)
);

assign address_a = pc_out;
assign read_a = 1'b1;

// pass through our input values 
assign out.pc = pc_out;
assign out.ctrl = regs_in.ctrl;
assign out.valid = regs_in.valid;

register #($bits(out)) stage_reg (
	.clk(clk),
	.load(resp_a),
	.in(out),
	.out(regs_out)
);

endmodule: fetch
