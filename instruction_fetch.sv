import rv32i_types::*;

module fetch (
    input clk, 
	 output logic read_a,
	 input resp_a,
	 input resp_b,
	 input read_b,
	 input write,
	 output rv32i_word address_a,
    input stage_regs regs_in,
    output rv32i_word pc
); 

//initial
//begin
//    read_a = 1'b1;
//end

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
	.load(resp_a | resp_b), 
	.in(pcmux_out),
	.out(pc_out)
);

pc_plus4 pc_plus4 (
	.in(pc_out), 
	.out(pc_plus4_out)
);

assign address_a = pc_out;
assign read_a = ~read_b & ~write;

register stage_reg (
	.clk(clk),
	.load(resp_a | resp_b),
	.in(pc_out),
	.out(pc)
);

endmodule: fetch
