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
	input rv32i_word rdata_b,
	
	output logic [31:0] branch_total_count,
	output logic [31:0] branch_incorrect_count,
    
	input logic branch_total_reset,
	input logic branch_incorrect_reset
);


stage_regs stage_one_regs, stage_two_regs, stage_three_regs, stage_four_regs, stage_five_regs;

logic ld_regfile;
logic [4:0] rd;
logic stall_in,stallreg_in;
logic reset_mux;
rv32i_word rd_data;
rv32i_word pc;
rv32i_word instruction;
rv32i_word dcache_out;
logic stall_out;
logic reset;
logic predict_addr;

rv32i_word alu_out;

logic hazard_wb_mem [2];
logic hazard_wb_exec [2];
logic hazard_wb_dec [2];
logic hazard_mem_exec [2];
logic hazard_exe_dec [2];
logic [31:0] wb_mem, wb_dec, wb_exec, mem_exec;

predict_regs predict_fetch, predict_dec, predict_exec;

rv32i_word exec_forward;
rv32i_word mem_forward;

assign stallreg_in = (hazard_exe_dec [0] || hazard_exe_dec[1]) && ((stage_two_regs.ctrl.opcode == op_load) || (stage_two_regs.ctrl.opcode == op_lui)) && stage_two_regs.valid;

fetch stage_one
(
    .clk, 
	 .read_a,
	 .rdata_a,
	 .address_a,
	 .reset_mux(stage_four_regs.ctrl.pcmux_sel),
	 .resp_a,
	 .resp_b(~stall_out),
	 .regs_in(stage_three_regs),
	 .predict_regs_in(predict_exec),
    .predict_regs_out(predict_fetch),
	 .pc,
	 .stall_in(stallreg_in),
	 .predict_addr
);

decode stage_two
(
	.clk,
	.reset,
	.instruction(rdata_a), // from instruction cache
	.resp_a,
	.resp_b(~stall_out),
	.pc, // from fetch
	.cache_out(rd_data), // from wb
	.ld_regfile(ld_regfile), // from wb
	.rd(rd), // from wb
	.predict_regs_in(predict_fetch),
   .predict_regs_out(predict_dec),
	.regs_out(stage_two_regs),
	.regs_out_comb(stage_one_regs),
	.stall_in(stallreg_in),
	.hazard_wb_dec,
	.wb_dec
);

execute stage_three
(
	.clk,
	.reset,
	.resp_a,
	.resp_b(~stall_out),
	.regs_in(stage_two_regs),
	.regs_out(stage_three_regs),
	.stall_in(),
	.stall_out(),
	.alu_out,
	.predict_regs_in(predict_dec),
	.predict_regs_out(predict_exec),
	.hazard_mem_exec,
	.hazard_wb_exec,
	.wb_exec,
	.mem_exec
);

mem stage_four
(
	.clk,
	.reset,
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
	.stall_out,
	.hazard_wb_mem,
	.wb_mem,
	.predict_regs_in(predict_exec),
	.predict_addr,
	.branch_total_count,
	.branch_incorrect_count,
	.branch_total_reset,
	.branch_incorrect_reset
);

writeback stage_five
(
	.clk,
	.regs_in(stage_four_regs),
	.rd_data(rd_data),
	.ld_regfile(ld_regfile),
	.rd(rd),
	.dcache_out,
	.regs_out(stage_five_regs),
	.stall(stall_out)
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
