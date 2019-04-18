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

// prefetch
logic pre_resp_a;
logic [255:0] pre_rdata_a;
logic pre_read_a;

// ewb
logic ewb_resp_b;
logic ewb_write;
logic [255:0] ewb_wdata;
logic arb_ewb_resp;
rv32i_word ewb_addr;

// arbiter
logic arb_resp_a;
logic arb_resp_b;
rv32i_word pre_addr_a;
logic [255:0] arb_pre_rdata;
logic arb_pre_resp;

// L2_cache
logic L1_read;
logic L1_write;
rv32i_word L1_addr;
logic L1_resp;
logic [255:0] L1_rdata;
logic [255:0] L1_wdata;

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
	.pmem_wdata(),
	.pmem_error()
);

mux2 #(.width(256)) rdata_a_mux
(
	.sel(pre_resp_a),
	.a(arb_rdata_a),
	.b(pre_rdata_a),
	.f(cache_rdata_a)
);

assign cache_resp_a = arb_resp_a | pre_resp_a;
assign cache_resp_b = arb_resp_b | ewb_resp_b;

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
	.pmem_wdata(cache_wdata_b),
	.pmem_error()
);


prefetch prefetch
(
	.clk,
	
	.cache_read_a,
	.cache_addr_a,
	
	.pre_resp_a,
	.pre_rdata_a,
	.pre_read_a,
	.pre_addr_a,
	.arb_pre_rdata,
	.arb_pre_resp
);

external_write_buffer ewb
(
	.clk,
	
	.cache_read_b,
	.cache_write_b,
	.cache_addr_b,
	.cache_wdata_b,

	.arb_ewb_resp,
	.ewb_write,
	.ewb_wdata,
	.ewb_addr,
	.ewb_resp_b
);

L1_arbiter L1_arbiter
(
	.clk,
	
	// icache direct
	.cache_read_a,
	.cache_addr_a,
	.arb_rdata_a,
	.arb_resp_a,
	
	// prefetch
	.pre_read_a(1'b0),
	.pre_addr_a,
	.arb_pre_rdata,
	.arb_pre_resp,
	
	// ewb
	.arb_ewb_resp,
	.ewb_write,
	.ewb_wdata,
	.ewb_addr,
	
	// dcache
	.cache_read_b,
	.cache_addr_b,
	.cache_rdata_b,
	.arb_resp_b,

//	.pmem_read,
//	.pmem_write,
//	.pmem_address,
//	.pmem_resp,
//	.pmem_rdata,
//	.pmem_wdata

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
	
	.pmem_read,
	.pmem_write,
	.pmem_addr(pmem_address),
	.pmem_resp,
	.pmem_rdata,
	.pmem_wdata,
	.pmem_error()
);

// maybe put registers between L2_cache and pmem here, incur cycle delay, increase fmax

endmodule : mem_heirarchy
