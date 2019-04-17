import rv32i_types::*;

module mp3
(
	input clk,

	input pmem_resp,
	input pmem_error,
	input [255:0] pmem_rdata,

	output logic pmem_read,
	output logic pmem_write,
	output rv32i_word pmem_address,
	output logic [255:0] pmem_wdata
);

// port A
logic read_a;
rv32i_word address_a;
logic resp_a;
rv32i_word rdata_a;

// port B
logic read_b;
logic write;
logic [3:0] wmask;
rv32i_word address_b;
rv32i_word wdata;
logic resp_b;
rv32i_word rdata_b;

cpu cpu
(
	.*
);

cache_heirarchy cache_datapath
(
	.clk,

	// port A
	.read_a,
	.address_a,
	.resp_a,
	.rdata_a,

	// port B
	.read_b,
	.write,
	.wmask,
	.address_b,
	.wdata,
	.resp_b,
	.rdata_b,
	
	// pmem
	.pmem_resp,
	.pmem_error,
	.pmem_rdata,
	.pmem_wdata,
	.pmem_read,
	.pmem_write,
	.pmem_address
);

endmodule : mp3