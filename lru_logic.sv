module lru_logic #(
	parameter lru_bits = 3
)
(
	input logic hit_all,
	input logic hit [4],
	input logic [lru_bits-1:0] lru_in,
	output logic [lru_bits-1:0] lru_out
);

// bits are: top bit, c/d, a/b

logic [lru_bits-1:0] hit_way;
logic [lru_bits-1:0] miss_way;

lru_one_hot_mux lru_hit_mux 
(
	.sel(hit),
	.a((lru_in & 3'b010) | 3'b100),
	.b((lru_in & 3'b010) | 3'b101),
	.c((lru_in & 3'b001) | 3'b000),
	.d((lru_in & 3'b001) | 3'b010),
	.f(hit_way)
);

mux2 #(.width(lru_bits)) lru_out_mux
(
	.sel(hit_all),
	.a(miss_way),
	.b(hit_way),
	.f(lru_out)
);

mux8 #(.width(3)) lru_miss_mux
(
	.sel(lru_in),
	.a(3'b101),
	.b(3'b100),
	.c(3'b111),
	.d(3'b110),
	.e(3'b010),
	.f(3'b011),
	.g(3'b000),
	.h(3'b001),
	.out(miss_way)
);


endmodule : lru_logic