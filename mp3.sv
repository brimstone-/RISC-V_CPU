import rv32i_types::*;

module mp3
(
	input clk,
	
	input logic pmem_resp, pm_error,
	input logic [255:0] pmem_rdata,
	
	output pmem_read,
	output pmem_write,
	output [31:0] pmem_address,
	output [255:0] pmem_wdata
);

logic mem_read, mem_write, mem_resp;
logic [31:0] mem_address;
logic [31:0] mem_wdata;
logic [31:0] mem_rdata;
logic [3:0] mem_byte_enable;

cpu cpu
(
	.clk,
	.mem_resp(mem_resp),
	.mem_rdata(mem_rdata),
	.mem_read(mem_read),
	.mem_write(mem_write),
	.mem_byte_enable(mem_byte_enable),
	.mem_address(mem_address),
	.mem_wdata(mem_wdata)
);

endmodule : mp3