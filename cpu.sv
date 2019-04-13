import rv32i_types::*;

module cpu
(
	input clk,

	// port A
	output logic read_a,
	output rv32i_word address_a,
	input resp_a,
	input rv32i_word rdata_a,
	
	// port B
	output logic read_b,
	output logic write,
	output logic [3:0] wmask,
	output rv32i_word address_b,
	output rv32i_word wdata,
	input resp_b,
	input rv32i_word rdata_b
);


stage_regs stage_one_regs, stage_two_regs, stage_three_regs, stage_four_regs, stage_five_regs;

logic ld_regfile;
logic [4:0] rd;
logic stall_in,stallreg_in;

rv32i_word rd_data;
rv32i_word pc;
rv32i_word instruction;
rv32i_word dcache_out;

rv32i_word alu_out;

logic hazard_wb_mem [2];
logic hazard_wb_exec [2];
logic hazard_wb_dec [2];
logic hazard_mem_exec [2];
logic hazard_exe_dec [2];
logic [31:0] wb_mem, wb_dec, wb_exec, mem_exec;

rv32i_word exec_forward;
rv32i_word mem_forward;

assign stallreg_in = (hazard_exe_dec [0] || hazard_exe_dec[1]) && (stage_two_regs.ctrl.opcode == op_load) && stage_two_regs.valid;

register #(.width(1)) stall_reg
(
	.clk,
	.load(1'b1),
	.reset(1'b0),
	.in(stallreg_in),
	.out(stall_in)
);

fetch stage_one
(
    .clk, 
	 .read_a,
	 .rdata_a,
	 .address_a,
	 .resp_a,
	 .resp_b,
	 .regs_in(stage_three_regs),
    .pc,
	 .instruction,
	 .stall_in(stallreg_in || stall_in)
);

decode stage_two
(
	.clk,
	.reset(stage_three_regs.ctrl.pcmux_sel),
	.instruction, // from instruction cache
	.resp_a,
	.resp_b,
	.pc, // from fetch
	.cache_out(rd_data), // from wb
	.ld_regfile(ld_regfile), // from wb
	.rd(rd), // from wb
	.regs_out(stage_two_regs),
	.regs_out_comb(stage_one_regs),
	.stall_in,
	.hazard_wb_dec,
	.wb_dec
);

execute stage_three
(
	.clk,
	.reset(stage_three_regs.ctrl.pcmux_sel),
	.resp_a,
	.resp_b,
	.regs_in(stage_two_regs),
	.regs_out(stage_three_regs),
	.stall_in(),
	.stall_out(),
	.alu_out,
	.hazard_mem_exec,
	.hazard_wb_exec,
	.wb_exec,
	.mem_exec
);

mem stage_four
(
	.clk,
	.reset(1'b0),
	.regs_in(stage_three_regs),
	.resp_a,
	.resp_b,
	.read_b,
	.rdata_b,
	.write,
	.wmask,
	.address_b,
	.wdata,
	.dcache_out,
	.regs_out(stage_four_regs),
	.stall_in(),
	.stall_out(),
	.hazard_wb_mem,
	.wb_mem
);

writeback stage_five
(
	.regs_in(stage_four_regs),
	.rd_data(rd_data),
	.ld_regfile(ld_regfile),
	.rd(rd),
	.dcache_out,
	.regs_out(stage_five_regs)
);

forward forwarding_unit
(
	.de(stage_one_regs), 
	.exe(stage_two_regs), 
	.mem(stage_three_regs), 
	.wb(stage_four_regs),
	.cache_data(rd_data),
	.hazard_wb_mem,
	.hazard_wb_exec,
	.hazard_wb_dec,
	.hazard_mem_exec,
	.hazard_exe_dec,
	.wb_mem, 
	.wb_exec, 
	.wb_dec, 
	.mem_exec
);

endmodule : cpu
