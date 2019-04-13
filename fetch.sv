import rv32i_types::*;

module fetch (
    input clk, 
	 output logic read_a,
	 input rv32i_word rdata_a,
	 input resp_a,
	 input resp_b,
	 output rv32i_word address_a,
    input stage_regs regs_in,
    output rv32i_word pc,
	 output rv32i_word instruction,
	 input stall_in
	 /* input ex_fetch_haz,
	 input rv32i_word exec_forward */
);

stage_regs regs_out;
rv32i_word pcmux_out;
rv32i_word pc_out;

rv32i_word pc_plus4_out;

mux2 pc_mux
(
	.sel(regs_in.ctrl.pcmux_sel),
	.a(pc_plus4_out),
	.b(regs_in.alu),
	.f(pcmux_out)
);

/*
mux4 pc_mux (
	.sel({ex_fetch_haz & regs_in.br[0], regs_in.ctrl.pcmux_sel}),
	.a(pc_plus4_out),
	.b(regs_in.pc),
	.c(exec_forward),
	.d(exec_forward),
	.f(pcmux_out)
);
*/
pc_register pc_reg (
	.clk(clk),
	.load(resp_b & resp_a && (stall_in == 0)), 
	.in(pcmux_out),
	.out(pc_out)
);


assign pc_plus4_out = pc_out + 4;


assign address_a = pc_out;
initial begin
	read_a = 1;
end

always_ff @(posedge clk)
begin
	read_a = 1'b1;
end

register stage_reg (
	.clk(clk),
	.reset(regs_in.ctrl.pcmux_sel),
	.load((stall_in == 0) & resp_a & resp_b),
	.in(pc_out),
	.out(pc)
);

register rdata (
	.clk,
	.reset(regs_in.ctrl.pcmux_sel),
	.load((stall_in == 0) & resp_a & resp_b),
	.in(rdata_a),
	.out(instruction)
);

endmodule: fetch
