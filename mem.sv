import rv32i_types::*;

module mem (
	input logic clk,

	output logic reset,
	input stage_regs regs_in, 
	
	input logic resp_a,
	input logic resp_b,
	
	input rv32i_word rdata_b,

	output logic read_b,
	output logic write,
	output logic [3:0] wmask,
	output rv32i_word address_b,
	output rv32i_word wdata,
	
	output stage_regs regs_out,
	output rv32i_word dcache_out,
	input logic hazard_wb_mem[2],
	input logic [31:0] wb_mem,
	input stall_in,
	output logic stall_out,
	output logic predict_addr,
	input predict_regs predict_regs_in,
	
	output logic [31:0] branch_total_count,
	output logic [31:0] branch_incorrect_count,
	
	input logic branch_total_reset,
	input logic branch_incorrect_reset
); 

logic [31:0] write_data;

logic load_branch_total, load_branch_incorrect;
logic [31:0] branch_total_out, branch_incorrect_out;

assign read_b = regs_in.ctrl.read_b;
assign write = regs_in.ctrl.write;
assign address_b = regs_in.alu;
mux2 wdata_mux
(
	.sel(hazard_wb_mem[1]),
	.a(regs_in.rs2),
	.b(wb_mem),
	.f(write_data)
);

assign reset = (predict_regs_in.taken ^ regs_in.ctrl.pcmux_sel) || ((predict_addr == 0) && (predict_regs_in.taken && regs_in.ctrl.pcmux_sel));
assign predict_addr = predict_regs_in.btb_address == regs_in.alu;
assign stall_out = (read_b | write) && (resp_b == 0);

register #($bits(regs_in)) stage_reg (
	.clk(clk),
	.reset(1'b0),
	.load(resp_a && (~stall_out)),
	.in(regs_in),
	.out(regs_out)
);

store_mask store_mask
(
	.store_type(regs_in.ctrl.store_type),
	.store_data(write_data),
	.alu_out(regs_in.alu[1:0]),
	.mem_wdata(wdata),
	.out(wmask)
);

register rdata
(
	.clk,
	.reset(1'b0),
	.load(resp_b && read_b && resp_a),
	.in(rdata_b),
	.out(dcache_out)
);

assign load_branch_total = (regs_in.ctrl.opcode == op_br | regs_in.ctrl.opcode == op_jal | regs_in.ctrl.opcode == op_jalr) & ~stall_out;
assign branch_total_count = branch_total_out;
register #(.width(32)) branch_total_reg
(
	.clk,
	.load(load_branch_total),
	.reset(branch_total_reset),
	.in(branch_total_out + 1),
	.out(branch_total_out)
);

assign branch_incorrect_count = branch_incorrect_out;
assign load_branch_incorrect  = reset & load_branch_total;
register #(.width(32)) branch_incorrect_reg
(
	.clk,
	.load(load_branch_incorrect),
	.reset(branch_incorrect_reset),
	.in(branch_incorrect_out + 1),
	.out(branch_incorrect_out)
);

endmodule: mem
