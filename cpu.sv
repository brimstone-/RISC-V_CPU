import rv32i_types::*;

module cpu
(
//	input clk,
//	input mem_resp,
//	input rv32i_word mem_rdata,
//	
//	output logic mem_read,
//	output logic mem_write,
//	output rv32i_mem_wmask mem_byte_enable,
//	output logic [31:0] mem_address,
//	output logic [31:0] mem_wdata
	 input [31:0] reg_in,
    input [31:0] pc,
	 input [31:0] cache_out,
    input logic ld_regfile,
    input [4:0] rd,
	 input clk,
	 output stage_regs out_tb
);

//fetch
//(
//	.*
//);

stage_regs out;

decode stage_two
(
	 .reg_in,
    .pc,
	 .cache_out,
    .ld_regfile,
    .rd,
	 .clk,
	 .regs(out)
);

execute stage_three
(
	.clk,
	.in(out),
	.regs(out_tb)
);

//memory
//(
//	.*
//);

//writeback
//(
//	.*
//);

endmodule : cpu
