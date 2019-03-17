import rv32i_types::*;

module mem (
    input logic clk, 
    input stage_regs regs_in, 

    output stage_regs regs_out
); 

// without cache, we don't do much in this stage right? 
assign out.pc = in.pc;
assign out.ctrl = in.ctrl;
assign out.alu = in.alu;
assign out.rd = in.rd;
assign out.br = in.br;              // aready zext in EX stage 
assign out.valid = in.valid;
// TODO: pass PC to dCache for WB stage 

register #($bits(out)) stage_reg (
	.clk(clk),
	.load(1'b1),
	.in(out),
	.out(regs_out)
);

endmodule: mem
