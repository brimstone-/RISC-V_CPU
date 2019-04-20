import rv32i_types::*;

module L2_arbiter
(
	input clk,

	// from/to L2
	input L2_read,
	input L2_write,
	input rv32i_word L2_addr,
	output logic [255:0] L2_rdata,
	input [255:0] L2_wdata,
	output logic L2_arb_resp,
	
	// from/to prefetcher
	input pre_read,
	input rv32i_word pre_addr,
	output logic [255:0] arb_pre_rdata,
	output logic arb_pre_resp,
	
	// pmem
	output logic pmem_read,
	output logic pmem_write,
	output rv32i_word pmem_address,
	input pmem_resp,
	input [255:0] pmem_rdata,
	output logic [255:0] pmem_wdata
);

rv32i_word addr_mux_out;
logic addr_mux_sel;
logic load_rdata, load_wdata, load_addr;
logic [255:0] rdata_out, wdata_out;
logic load_type, pre_hit;
logic transaction_type_in, transaction_type_out;

assign pre_hit = L2_addr == pre_addr;

mux2 addr_mux
(
	.sel(addr_mux_sel),
	.a(L2_addr),
	.b(pre_addr),
	.f(addr_mux_out)
);

register addr_reg
(
	.clk,
	.load(load_addr),
	.reset(1'b0),
	.in(addr_mux_out),
	.out(pmem_address)
);

assign arb_pre_rdata = rdata_out;
assign L2_rdata = rdata_out;

register #(.width(256)) rdata_reg
(
	.clk,
	.load(load_rdata),
	.reset(1'b0),
	.in(pmem_rdata),
	.out(rdata_out)	
);

register #(.width(256)) wdata_reg
(
	.clk,
	.load(load_wdata),
	.reset(1'b0),
	.in(L2_wdata),
	.out(pmem_wdata)
);

/*
	0 = demand read/write
	1 = prefetch
*/
register #(.width(1)) transaction_type_reg
(
	.clk,
	.load(load_type),
	.reset(1'b0),
	.in(transaction_type_in),
	.out(transaction_type_out)
);

enum int unsigned {
	idle,
	demand_read,
	demand_write,
	prefetch,
	reading,
	writing,
	finish
} state, next_state;

always_comb
begin : state_actions
	/* Default output assignments */
	addr_mux_sel = 0;
	load_addr = 0;

	load_rdata = 0;
	load_wdata = 0;

	load_type = 0;
	transaction_type_in = 0;

	pmem_read = 0;
	pmem_write = 0;

	L2_arb_resp = 0;
	arb_pre_resp = 0;

	case(state)
		idle: ;
		demand_read: begin
			addr_mux_sel = 0;
			load_addr = 1;
			load_type = 1;
			transaction_type_in = 0;
		end
		demand_write: begin
			addr_mux_sel = 0;
			load_addr = 1;
			load_wdata = 1;
			load_type = 1;
			transaction_type_in = 0;
		end
		prefetch: begin
			addr_mux_sel = 1;
			load_addr = 1;
			load_type = 1;
			transaction_type_in = 1;
		end
		reading: begin
			pmem_read = 1;
			load_rdata = 1;
		end
		writing: begin
			pmem_write = 1;
		end
		finish: begin
			case (transaction_type_out)
				0: L2_arb_resp = 1;
				1: arb_pre_resp = 1;
				default: ;
			endcase // transaction_type_out
		end
		default: ;
	endcase
end

always_comb
begin : next_state_logic
	next_state = state;
	case(state)
		idle: begin
			if (L2_read & ~pre_hit) next_state = demand_read;
			else if (L2_write) next_state = demand_write;
			else if (pre_read) next_state = prefetch;
			else next_state = idle;
		end

		demand_read: next_state = reading;
		demand_write: next_state = writing;
		prefetch: next_state = reading;

		reading: begin
			if (pmem_resp) next_state = finish;
			else next_state = reading;
		end
		writing: begin
			if (pmem_resp) next_state = finish;
			else next_state = writing;
		end

		finish: next_state = idle;

		default: next_state = idle;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
	/* Assignment of next state on clock edge */
	state <= next_state;
end

endmodule : L2_arbiter
