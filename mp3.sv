import rv32i_types::*;

module mp3
(
	input clk,

	// port A
	output read_a,
	output [31:0] address_a,
	input resp_a,
	input [31:0] rdata_a,
	
	// port B
	input read_b,
	input write,
	input [3:0] wmask,
	input [31:0] address_b,
	input [31:0] wdata,
	output logic resp_b,
	output logic [31:0] rdata_b
);

cpu cpu
(
	.*
);

endmodule : mp3