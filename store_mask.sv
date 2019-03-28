module store_mask
(
	input [1:0] store_type
	input [1:0] alu_out
	output logic [3:0] out
);

logic [3:0] byte_mux_out;
logic [3:0] half_mux_out;
logic [3:0] word;

assign word = 4'b1111;

mux4 #(.width(4)) byte_mux
(
	.sel(alu_out),
	.a(4'b0001),
	.b(4'b0010),
	.c(4'b0100),
	.d(4'b1000),
	.f(byte_mux_out)
);

mux2 #(.width(4)) half_mux_out
(
	.sel(alu_out[1]),
	.a(4'b0011),
	.b(4'b1100),
	.f(half_mux_out)
);

mux4 #(.width(4)) wmask_mux
(
	.sel(store_type),
	.a(word),
	.b(byte_mux_out),
	.c(half_mux_out),
	.d(),
	.f(out)
);

endmodule : store_mask
