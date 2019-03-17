import rv32i_types::*;

module mp3
(
	input clk,

	// port A
	output logic read_a,
	output logic [31:0] address_a,
	input resp_a,
	input [31:0] rdata_a,
	
	// port B
	output logic read_b,
	output logic write,
	output logic [3:0] wmask,
	output logic [31:0] address_b,
	output logic [31:0] wdata,
	input resp_b,
	input [31:0] rdata_b
);

cpu cpu
(
	.*
);

endmodule : mp3