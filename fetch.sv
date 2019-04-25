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
	input predict_addr,
	
	output rv32i_word branch_total_count,
	output rv32i_word branch_correct_count,
	output rv32i_word branch_incorrect_count,
	
	input branch_total_reset,
	input branch_correct_reset,
	input branch_incorrect_reset
);

predict_regs predict_regs_internal;

rv32i_word pcmux_out;
rv32i_word pc_out;

rv32i_word target;
rv32i_word taken_mux_out, not_taken_mux_out;

logic taken, taken_hit, btb_hit;
logic [1:0] mux_sel;
logic [3:0] select;

logic load_branch_total;
logic load_branch_correct;
logic load_branch_correct_final;
logic load_branch_incorrect;
logic load_branch_incorrect_final;

logic [31:0] branch_total_out;
logic [31:0] branch_correct_out;
logic [31:0] branch_incorrect_out;

assign select = {predict_addr,regs_in.ctrl.pcmux_sel,predict_regs_in.taken,taken_hit};

always_comb
begin
	mux_sel = 0;
	load_branch_correct = 0;
	load_branch_incorrect = 0;
	casex(select)
      4'b0110: begin
         mux_sel = 3;
         load_branch_incorrect = 1;
      end               // we predicted branch, we branched, we got the wrong address (incorrect)
      4'b0111: begin
         mux_sel = 3;
         load_branch_incorrect = 1;
      end            // we predicted branch, we branched, we got the wrong address (incorrect)
      4'b1110: begin
         mux_sel = 0;
         load_branch_correct = 1;
      end            // we predicted branch, we did branch, addresses were correct, do not predict branch (correct)
      4'b1111: begin
         mux_sel = 1;
         load_branch_correct = 1;
      end            // we predicted branch, we did branch, addresses were correct, predict branch (correct)
      4'b?000: begin
         mux_sel = 0;
         load_branch_correct = 1;
      end               // we did not predict branch, we did not branch, do no predict branch (correct)
      4'b?001: begin
         mux_sel = 1;
         load_branch_correct = 1;
      end            // we did not predict branch, we did not branch, predict branch (correct)
      4'b?010: begin
         mux_sel = 2;
         load_branch_incorrect = 1;
      end            // we predicted branch, we did not branch (incorrect)
      4'b?011: begin
         mux_sel = 2;
         load_branch_incorrect = 1;
      end            // we predicted branch, we did not branch (incorrect)
      4'b?100: begin
         mux_sel = 3;
         load_branch_incorrect = 1;
      end            // we did not predict branch, we did branch (incorrect)
      4'b?101: begin
         mux_sel = 3;
         load_branch_incorrect = 1;
      end            // we did not predict branch, we did branch (incorrect)
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

assign load_branch_total = (regs_in.ctrl.opcode == op_br | regs_in.ctrl.opcode == op_jal | regs_in.ctrl.opcode == op_jalr);
assign branch_total_count = branch_total_out;
register #(.width(32)) branch_total_reg
(
	.clk,
	.load(load_branch_total),
	.reset(branch_total_reset),
	.in(branch_total_out + 1),
	.out(branch_total_out)
);

assign branch_correct_count = branch_correct_out;
assign load_branch_correct_final = load_branch_correct & load_branch_total;
register #(.width(32)) branch_correct_reg
(
	.clk,
	.load(load_branch_correct_final),
	.reset(branch_correct_reset),
	.in(branch_correct_out + 1),
	.out(branch_correct_out)
);

assign branch_incorrect_count = branch_incorrect_out;
assign load_branch_incorrect_final = load_branch_incorrect & load_branch_total;
register #(.width(32)) branch_incorrect_reg
(
	.clk,
	.load(load_branch_incorrect_final),
	.reset(branch_incorrect_reset),
	.in(branch_incorrect_out + 1),
	.out(branch_incorrect_out)
);

endmodule: fetch
