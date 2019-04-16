import rv32i_types::*;

module cache_heirarchy
(
	input clk,

	// port A
	input read_a,
	input rv32i_word address_a,
	output logic resp_a,
	output rv32i_word rdata_a,

	// port B
	input read_b,
	input write,
	input [3:0] wmask,
	input rv32i_word address_b,
	input rv32i_word wdata,
	output logic resp_b,
	output rv32i_word rdata_b,
	
	// pmem
	input pmem_resp,
	input pmem_error,
	input [255:0] pmem_rdata,

	output [255:0] pmem_wdata,
	output logic pmem_read,
	output logic pmem_write,
	output rv32i_word pmem_address
);

rv32i_word pmem_address_a, pmem_address_b;

logic resp_arb_a, resp_arb_b;
logic pmem_read_a, pmem_read_b, pmem_write_b;
logic error_arb_a, error_arb_b;
logic arb_pmem_resp, arb_pmem_read, arb_pmem_write;
logic [31:0] arb_pmem_address;
logic [255:0] arb_pmem_rdata, arb_pmem_wdata;

logic [255:0] rdata_arb;

logic read_i, read_d, write_d;
logic [255:0] pmem_wdata_b;

// a
o_cache icache
(
	.clk,
	.mem_read(read_a),
	.mem_write(1'b0),
	.mem_addr(address_a),
	.mem_wdata(),
	.mem_byte_enable(4'b1111),

	.mem_resp(resp_a),
	.mem_rdata(rdata_a),

	.pmem_resp(resp_arb_a),
	.pmem_error(error_arb_a),
	.pmem_rdata(rdata_arb),

	.pmem_read(pmem_read_a),
	.pmem_write(),
	.pmem_addr(pmem_address_a),
	.pmem_wdata()
);

// b
o_cache dcache
(
	.clk,
	.mem_read(read_b ),
	.mem_write(write),
	.mem_addr(address_b),
	.mem_wdata(wdata),
	.mem_byte_enable(wmask),
	.mem_resp(resp_b),
	.mem_rdata(rdata_b),

	.pmem_resp(resp_arb_b),
	.pmem_error(error_arb_b),
	.pmem_rdata(rdata_arb),

	.pmem_read(pmem_read_b),
	.pmem_write(pmem_write_b),
	.pmem_addr(pmem_address_b),
	.pmem_wdata(pmem_wdata_b)
);

arbiter arbiter
(
	// to both
	.cache_rdata(rdata_arb),
	
	// icache
	.pmem_resp_a(resp_arb_a),
	.pmem_error_a(error_arb_a),

	.pmem_read_a(pmem_read_a),
	.pmem_address_a(pmem_address_a),

	// dcache
	.pmem_resp_b(resp_arb_b),
	.pmem_error_b(error_arb_b),

	.pmem_read_b(pmem_read_b),
	.pmem_write_b(pmem_write_b),
	.pmem_address_b(pmem_address_b),
	.pmem_wdata_b(pmem_wdata_b),
	
	// pmem
	.pmem_resp,
	.pmem_error,
	.pmem_rdata,
	.pmem_wdata, // should hook up as full liney
	.pmem_read,
	.pmem_write,
	.pmem_address
);

endmodule : cache_heirarchy
