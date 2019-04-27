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
	input reset_mux,
	input stall_in,
	input predict_addr
);

predict_regs predict_regs_internal;

rv32i_word pcmux_out;
rv32i_word pc_out;

rv32i_word target;
rv32i_word taken_mux_out, not_taken_mux_out;

logic taken, taken_hit, btb_hit;
logic [1:0] mux_sel;
logic [3:0] select;

logic [31:0] branch_total_out;
logic [31:0] branch_correct_out;
logic [31:0] branch_incorrect_out;

assign select = {predict_addr,regs_in.ctrl.pcmux_sel,predict_regs_in.taken,taken_hit};

always_comb
begin
	mux_sel = 0;
	casex(select)
		4'b0110: mux_sel = 3;       // we predicted branch, we branched, we got the wrong address
		4'b0111: mux_sel = 3;		 // we predicted branch, we branched, we got the wrong address
		4'b1110: mux_sel = 0;		 // we predicted branch, we did branch, addresses were correct, do not predict branch
		4'b1111:	mux_sel = 1;		 // we predicted branch, we did branch, addresses were correct, predict branch
		4'b?000: mux_sel = 0;       // we did not predict branch, we did not branch, do no predict branch
		4'b?001: mux_sel = 1;		 // we did not predict branch, we did not branch, predict branch
		4'b?010: mux_sel = 2;		 // we predicted branch, we did not branch
		4'b?011: mux_sel = 2;		 // we predicted branch, we did not branch
		4'b?100: mux_sel = 3;		 // we did not predict branch, we did branch
		4'b?101: mux_sel = 3;	 	 // we did not predict branch, we did branch
	endcase
end

mux4 pc_mux
(
	.sel(mux_sel),
	.a(pc_out + 4),
	.b(target),
	.c(regs_in.pc + 4),
	.d(regs_in.alu),
	.f(pcmux_out)
);

pc_register pc_reg (
	.clk(clk),
	.load(resp_a && resp_b && ((stall_in == 0) || ((mux_sel != 0) && (mux_sel != 1)))),
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
	read_a = resp_b;
end

gshare #(.sr_size(6)) branch_predictor
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
assign predict_regs_internal.btb_address = target;

branch_target_buffer #(.s_index(9)) btb
(
	.clk,
    
	.fetch_pc(pc), // from fetch, to check hit
	.target, // to fetch
	.hit(btb_hit), // to fetch
    
	.pcmux_sel(regs_in.ctrl.pcmux_sel),
	.alu_out(regs_in.alu), // from execute, to fill data
	.exec_pc(regs_in.pc) // from execute, to fill tag
);

assign predict_regs_out = predict_regs_internal;

endmodule: fetch
