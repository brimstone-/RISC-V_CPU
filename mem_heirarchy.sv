import rv32i_types::*;

module mem_heirarchy
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
	output logic pmem_read,
	output logic pmem_write,
	output rv32i_word pmem_address,
	input [255:0] pmem_rdata,
	output [255:0] pmem_wdata,
	input pmem_resp
);

// signals for L1 cache <-> L1 arbiter
// icache
rv32i_word cache_addr_a;
logic cache_resp_a;
logic cache_read_a;
logic [255:0] cache_rdata_a;
logic [255:0] arb_rdata_a;

// dcache
rv32i_word cache_addr_b;
logic cache_resp_b;
logic cache_read_b;
logic cache_write_b;
logic [255:0] arb_rdata_b;
logic [255:0] cache_rdata_b;
logic [255:0] cache_wdata_b;

// ewb
logic ewb_resp;
logic ewb_write;
logic [255:0] ewb_wdata;
logic arb_ewb_resp;
rv32i_word ewb_addr;

// L2 arbiter
logic arb_resp_a;
logic arb_resp_b;

// L2_cache
logic L1_read;
logic L1_write;
rv32i_word L1_addr;
logic L1_resp;
logic [255:0] L1_rdata;
logic [255:0] L1_wdata;

logic L2_read;
logic L2_write;
logic L2_resp;
logic L2_arb_resp;
rv32i_word L2_addr;
logic [255:0] L2_rdata;
logic [255:0] L2_arb_rdata;
logic [255:0] L2_wdata;

logic pre_resp;
logic [255:0] pre_rdata;
logic pre_read;
rv32i_word pre_addr;
logic [255:0] arb_pre_rdata;
logic arb_pre_resp;

// icache
o_cache icache
(
	.clk,

	.mem_read(read_a),
	.mem_write(1'b0),
	.mem_addr(address_a),
	.mem_rdata(rdata_a),
	.mem_wdata(),
	.mem_byte_enable(4'b1111),
	.mem_resp(resp_a),
	
	.pmem_read(cache_read_a),
	.pmem_write(),
	.pmem_addr(cache_addr_a),
	.pmem_resp(cache_resp_a),
	.pmem_rdata(cache_rdata_a),
	.pmem_wdata()
);

// d cache
o_cache dcache
(
	.clk,

	.mem_read(read_b),
	.mem_write(write),
	.mem_addr(address_b),
	.mem_rdata(rdata_b),
	.mem_wdata(wdata),
	.mem_byte_enable(wmask),
	.mem_resp(resp_b),
	
	.pmem_read(cache_read_b),
	.pmem_write(cache_write_b),
	.pmem_addr(cache_addr_b),
	.pmem_resp(cache_resp_b),
	.pmem_rdata(cache_rdata_b),
	.pmem_wdata(cache_wdata_b)
);

assign cache_rdata_a = arb_rdata_a;
assign cache_resp_a = arb_resp_a;
assign cache_resp_b = arb_resp_b;

L1_arbiter L1_arbiter
(
	.clk,
	
	// icache direct
	.cache_read_a,
	.cache_addr_a,
	.arb_rdata_a,
	.arb_resp_a,
	
	// dcache
	.cache_read_b,
	.cache_write_b,
	.cache_addr_b,
	.cache_rdata_b,
	.cache_wdata_b,
	.arb_resp_b,

	// pmem
	.pmem_read(L1_read),
	.pmem_write(L1_write),
	.pmem_address(L1_addr),
	.pmem_resp(L1_resp),
	.pmem_rdata(L1_rdata),
	.pmem_wdata(L1_wdata)
);

L2_cache #(.s_index(4)) L2_cache
(
	.clk,

	.mem_read(L1_read),
	.mem_write(L1_write),
	.mem_addr(L1_addr),
	.mem_rdata(L1_rdata),
	.mem_wdata(L1_wdata),
	.mem_resp(L1_resp),

	.pmem_read(L2_read),
	.pmem_write(L2_write),
	.pmem_addr(L2_addr),
	.pmem_resp(L2_resp),
	.pmem_rdata(L2_rdata),
	.pmem_wdata(L2_wdata)
);

assign L2_resp = pre_resp | ewb_resp | L2_arb_resp;

mux2 #(.width(256)) L2_rdata_mux
(
	.sel(pre_resp),
	.a(L2_arb_rdata),
	.b(pre_rdata),
	.f(L2_rdata)
);

prefetch prefetch
(
	.clk,

	.cache_read(L2_read),
	.cache_addr(L2_addr),

	.pre_resp,
	.pre_rdata,
	.pre_read,
	.pre_addr,
	.arb_pre_rdata,
	.arb_pre_resp
);

external_write_buffer ewb
(
	.clk,
	
	.cache_read(L2_read),
	.cache_write(L2_write),
	.cache_addr(L2_addr),
	.cache_wdata(L2_wdata),

	.arb_ewb_resp,
	.ewb_write,
	.ewb_wdata,
	.ewb_addr,
	.ewb_resp
);

L2_arbiter L2_arbiter
(
	.clk,

	// from/to L2
	.L2_read,
	.L2_addr,
	.L2_rdata(L2_arb_rdata),
	.L2_arb_resp,
	
	// from/to prefetcher
	.pre_read,
	.pre_addr,
	.arb_pre_rdata,
	.arb_pre_resp,

	// ewb
	.arb_ewb_resp,
	.ewb_write,
	.ewb_wdata,
	.ewb_addr,
	
	// pmem
	.pmem_read,
	.pmem_write,
	.pmem_address,
	.pmem_resp,
	.pmem_rdata,
	.pmem_wdata
);

endmodule : mem_heirarchy
