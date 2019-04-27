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

// counter signals
logic [31:0] branch_total_count;
logic [31:0] branch_incorrect_count;

logic branch_total_reset;
logic branch_incorrect_reset;

cpu cpu
(
	.*
);

//cache_heirarchy cache_datapath
mem_heirarchy mem_heirarchy
(
	.*
);

endmodule : mp3