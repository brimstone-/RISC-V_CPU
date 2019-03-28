import rv32i_types::*;

module load_mask
(
	input [1:0] load_type,
	input [1:0] alu_out,
	input rv32i_word in,
	input load_unsigned,
	output rv32i_word out
);

rv32i_word signed_byte_mux_out;
rv32i_word unsigned_byte_mux_out;
rv32i_word signed_half_mux_out;
rv32i_word unsigned_half_mux_out;
rv32i_word word;

assign word = in;

mux4 signed_byte_mux
(
	.sel(alu_out),
	.a({{24{in[ 7]}},in[ 7: 0]}),
	.b({{24{in[15]}},in[15: 8]}),
	.c({{24{in[23]}},in[23:16]}),
	.d({{24{in[31]}},in[31:24]}),
	.f(signed_byte_mux_out)
);

mux4 unsigned_byte_mux
(
	.sel(alu_out),
	.a({{24{1'b0}},in[7 :0]}),
	.b({{24{1'b0}},in[15: 8]}),
	.c({{24{1'b0}},in[23:16]}),
	.d({{24{1'b0}},in[31:24]}),
	.f(unsigned_byte_mux_out)
);

mux2 signed_half_mux
(
	.sel(alu_out[1]),
	.a({{16{in[15]}},in[15:0]}),
	.b({{16{in[15]}},in[31:16]}),
	.f(signed_half_mux_out)
);

mux2 unsigned_half_mux
(
	.sel(alu_out[1]),
	.a({{16{in[15]}},in[15:0]}),
	.b({{16{in[15]}},in[31:16]}),
	.f(unsigned_half_mux_out)
);

mux8 wmask_mux
(
	.sel({load_unsigned,load_type}),
	.a(word),
	.b(signed_byte_mux_out),
	.c(signed_half_mux_out),
	.d(),
	.e(),
	.f(unsigned_byte_mux_out),
	.g(unsigned_half_mux_out),
	.h(),
	.out(out)
);

endmodule : load_mask
