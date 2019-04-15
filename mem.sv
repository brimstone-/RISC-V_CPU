import rv32i_types::*;

module mem (
	input logic clk,

	input reset,
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
	output logic stall_out
); 

// without cache, we don't do much in this stage right? 
//assign out.pc = in.pc;
//assign out.ctrl = in.ctrl;
//assign out.alu = in.alu;
//assign out.rd = in.rd;
//assign out.br = in.br;              // aready zext in EX stage 
//assign out.valid = in.valid;

// TODO: pass PC to dCache for WB stage
assign read_b = regs_in.ctrl.read_b;
assign write = regs_in.ctrl.write;
assign wdata = regs_in.rs2;
mux2 addr_mux
(
	.sel(hazard_wb_mem[1]),
	.a(regs_in.alu),
	.b(wb_mem),
	.f(address_b)
);

// low most of the tim, so we ~ it, so that everything loads.
//assign stall_out = ~((read_b | write) & ~resp_b);
assign stall_out = (read_b | write) && (resp_b == 0);

register #($bits(regs_in)) stage_reg (
	.clk(clk),
	.reset(reset),
	.load(resp_a && (~stall_out)),
	.in(regs_in),
	.out(regs_out)
);

store_mask store_mask
(
	.store_type(regs_in.ctrl.store_type),
	.alu_out(regs_in.alu[1:0]),
	.out(wmask)
);
//assign dcache_out = rdata_b;
register rdata
(
	.clk,
	.reset(1'b0),
	.load(resp_b),
	.in(rdata_b),
	.out(dcache_out)
);

endmodule: mem
