import rv32i_types::*;

module cpu
(
	input clk,
	input mem_resp,
	input rv32i_word mem_rdata,
	
	output logic mem_read,
	output logic mem_write,
	output rv32i_mem_wmask mem_byte_enable,
	output logic [31:0] mem_address,
	output logic [31:0] mem_wdata
);

fetch
(
	.*
);

decode
(
	.*
);

execute
(
	.*
);

memory
(
	.*
);

writeback
(
	.*
);

endmodule : cpu
