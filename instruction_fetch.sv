import rv32i_types::*;

module instruction_fetch (
    input logic clk, 
    input stage_regs in, 

    output stage_regs regs
); 

stage_regs out;
rv32i_word pcmux_out;  
rv32i_word pc_out;     

mux2 pc_mux (
    .sel(in.ctrl.pcmux_sel),
    .a(pc_plus4_out),
    .b(in.pc),
    .f(pcmux_out)
);

pc_register pc (
    .clk(clk),
    .load(1'b1), 
    .in(pcmux_out),
    .out(pc_out), 
);

pc_plus4 pc_plus4 (
	.in(pc_out), 
	.out(pc_plus4_out)
);

// pass through our input values 
assign out.pc = pc_out;
assign out.ctrl = in.ctrl;
assign out.valid = in.valid;
// TODO: for cache, need to pass for iCache

register #($bits(out)) stage_reg (
	.clk(clk),
    .load(1'b1), 					
    .in(out),						
    .out(regs)						
);

endmodule: instruction_fetch