import rv32i_types::*;

module fetch (
    input clk, 
	 output logic read_a,
	 input rv32i_word rdata_a,
	 input resp_a,
	 input resp_b,
	 output rv32i_word address_a,
	 input predict_regs predict_regs_in,
	 output predict_regs predict_regs_out,
    input stage_regs regs_in,
    output rv32i_word pc,
	 input logic reset_mux,
	 input stall_in
);

predict_regs predict_regs_internal;

rv32i_word pcmux_out;
rv32i_word pc_out;

rv32i_word target;
rv32i_word taken_mux_out, not_taken_mux_out;

logic [2:0] bhr;
logic taken, taken_hit, btb_hit;

mux8 pc_mux
(
	.sel({regs_in.ctrl.pcmux_sel, predict_regs_in.taken, taken_hit}),
	.a(pc_out + 4),
	.b(target),
	.c(regs_in.pc + 4),
	.d(regs_in.pc + 4),
	.e(regs_in.alu),
	.f(regs_in.alu),
	.g(pc_out + 4),
	.h(target),
	.out(pcmux_out)
);

pc_register pc_reg (
	.clk(clk),
	.load(resp_a && resp_b && (stall_in == 0) || regs_in.ctrl.pcmux_sel || taken_hit),
	.in(pcmux_out),
	.out(pc_out)
);

assign pc = pc_out;

assign address_a = pc_out;
initial begin
	read_a = 1;
end

always_ff @(posedge clk)
begin
	read_a = 1'b0;
	if(resp_b)
		read_a = 1'b1;
end

gshare branch_predictor
(
	.clk,

	// fetch signals
	.fetch_pc(pc),
	.bhr_out(predict_regs_internal.bhr),
	.taken,

	// exec signals 
	.opcode(regs_in.ctrl.opcode),
	.exec_pc(regs_in.pc),
	.pcmux_sel(regs_in.ctrl.pcmux_sel),
	.bhr_in(predict_regs_in.bhr)
);

assign taken_hit = predict_regs_internal.taken;
assign predict_regs_internal.taken = taken & btb_hit;

branch_target_buffer btb
(
    .clk,
    
    .fetch_pc(pc), // from fetch, to check hit
    .target, // to fetch
    .hit(btb_hit), // to fetch
    
    .pcmux_sel(regs_in.ctrl.pcmux_sel),
    .alu_out(regs_in.alu), // from execute, to fill data
    .exec_pc(regs_in.pc) // from execute, to fill tag
);

register #($bits(predict_regs_internal)) bhr_reg
(
	 .clk,
    .load(resp_a && resp_b && (stall_in == 0) || regs_in.ctrl.pcmux_sel),
	 .reset(1'b0),
    .in(predict_regs_internal),
    .out(predict_regs_out)
);

endmodule: fetch
