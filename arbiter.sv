import rv32i_types::*;

module arbiter
(
	// to both
	output logic [255:0] cache_rdata,
	
	// icache
	output logic pmem_resp_a,
	output logic pmem_error_a,

	input pmem_read_a,
	input rv32i_word pmem_address_a,

	// dcache
	output logic pmem_resp_b,
	output logic pmem_error_b,

	input pmem_read_b,
	input pmem_write_b,
	input rv32i_word pmem_address_b,
	input [255:0] pmem_wdata_b,
	
	// pmem
	input pmem_resp,
	input pmem_error,
	input [255:0] pmem_rdata,
	output [255:0] pmem_wdata,
	output logic pmem_read,
	output logic pmem_write,
	output rv32i_word pmem_address
);

// read
mux2 #(.width(1)) read_mux
(
	.sel(pmem_read_a),
	.a(pmem_read_b),
	.b(pmem_read_a),
	.f(pmem_read)
);

// write
assign pmem_write = pmem_write_b & ~pmem_read_a;

// error
assign pmem_error_b = pmem_error & (~pmem_read_a & (pmem_read_b | pmem_write_b));
assign pmem_error_a = pmem_error & pmem_read_a;

// resp
assign pmem_resp_b = pmem_resp & (~pmem_read_a & (pmem_read_b | pmem_write_b));
assign pmem_resp_a = pmem_resp & pmem_read_a;

// rdata
assign cache_rdata = pmem_rdata;

// wdata
assign pmem_wdata = pmem_wdata_b;

// address
mux2 #(.width(32)) address_mux
(
	.sel(pmem_read_a),
	.a(pmem_address_b),
	.b(pmem_address_a),
	.f(pmem_address)
);

endmodule : arbiter
