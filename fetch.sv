import rv32i_types::*;

module fetch (
    input clk, 
	 output logic read_a,
	 input rv32i_word rdata_a,
	 input resp_a,
	 output rv32i_word address_a,
    input stage_regs regs_in,
    output rv32i_word pc,
	 output rv32i_word instruction,
	 input stall_in
);

stage_regs regs_out;
rv32i_word pcmux_out;
rv32i_word pc_out;

rv32i_word pc_plus4_out;

mux2 pc_mux (
	.sel(regs_in.ctrl.pcmux_sel),
	.a(pc_plus4_out),
	.b(regs_in.pc),
	.f(pcmux_out)
);

pc_register pc_reg (
	.clk(clk),
	.load(stall_in & resp_a || regs_in.ctrl.pcmux_sel), 
	.in(pcmux_out),
	.out(pc_out)
);


assign pc_plus4_out = pc_out + 4;


assign address_a = pc_out;

always_ff @(posedge clk)
begin
	read_a = 1'b1;
end

register stage_reg (
	.clk(clk),
	.reset(1'b0),
	.load(stall_in & resp_a),
	.in(pc_out),
	.out(pc)
);

register rdata (
	.clk,
	.reset(1'b0),
	.load(stall_in & resp_a),
	.in(rdata_a),
	.out(instruction)
);

endmodule: fetch
