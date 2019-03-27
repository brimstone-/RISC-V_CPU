module mux2_1hot #(parameter width = 256)
(
	input [1:0] sel,
	input [width-1:0] a, b,
	output logic [width-1:0] f
);

always_comb
begin
	unique case(sel)
		2'b10 : f = a;
		2'b01 : f = b;
		default : f = {width{1'bx}};
	endcase
end

endmodule : mux2_1hot
