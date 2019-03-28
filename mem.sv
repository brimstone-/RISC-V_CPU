import rv32i_types::*;

module mem (
	input logic clk, 
	input stage_regs regs_in, 
	
	input resp_a,
	input resp_b,

	output logic read_b,
	output logic write,
	output logic [3:0] wmask,
	output rv32i_word address_b,
	output rv32i_word wdata,
	
	output stage_regs regs_out
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
assign wmask = regs_in.ctrl.mem_byte_enable;
assign address_b = regs_in.pc;
assign wdata = regs_in.alu;

register #($bits(regs_in)) stage_reg (
	.clk(clk),
	.load(resp_a | resp_b),
	.in(regs_in),
	.out(regs_out)
);

endmodule: mem
