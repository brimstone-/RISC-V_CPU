import rv32i_types::*;

module mem (
	input logic clk,

	output logic reset,
	input stage_regs regs_in, 
	
	input resp_a,
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
	input predict_regs predict_regs_in
); 

logic [31:0] write_data;

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

endmodule: mem
