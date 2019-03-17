import rv32i_types::*;

module pc_plus4 #(parameter width = 32)
(
	input [width-1:0] in, 
	output logic [width-1:0] out
);

assign out = in + 8'h4; 

endmodule: pc_plus4