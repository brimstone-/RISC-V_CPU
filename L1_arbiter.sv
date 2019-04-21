import rv32i_types::*;

module L1_arbiter
(
	input clk,

	// icache direct (demand read a)
	input cache_read_a,
	input rv32i_word cache_addr_a,
	output logic [255:0] arb_rdata_a,
	output logic arb_resp_a,

	// dcache (demand read/write b)
	input cache_read_b,
	input cache_write_b,
	input rv32i_word cache_addr_b,
	output logic [255:0] cache_rdata_b,
	input [255:0] cache_wdata_b,
	output logic arb_resp_b,
	
	// pmem
	output logic pmem_read,
	output logic pmem_write,
	output rv32i_word pmem_address,
	input pmem_resp,
	input logic [255:0] pmem_rdata,
	output logic [255:0] pmem_wdata
);

rv32i_word addr_mux_out;
logic addr_mux_sel;
logic load_rdata, load_wdata, load_addr;
logic [255:0] rdata_out, wdata_out;
logic load_type;
logic transaction_type_in, transaction_type_out;

mux2 addr_mux
(
	.sel(addr_mux_sel),
	.a(cache_addr_a), // demand read a
	.b(cache_addr_b), // demand read/write b
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

assign arb_rdata_a = rdata_out;
assign cache_rdata_b = rdata_out;

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
	.in(cache_wdata_b),
	.out(pmem_wdata)
);

/*
	0 = read a
	1 = read/write b
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
	read_a,
	read_b,
	write_b,
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

	arb_resp_a = 0;
	arb_resp_b = 0;

	case(state)
		idle: ;
		read_a: begin
			addr_mux_sel = 0;
			load_addr = 1;
			load_type = 1;
			transaction_type_in = 0;
		end
		read_b: begin
			addr_mux_sel = 1;
			load_addr = 1;
			load_type = 1;
			transaction_type_in = 1;
		end
		write_b: begin
			addr_mux_sel = 1;
			load_addr = 1;
			load_wdata = 1;
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
				0: arb_resp_a = 1;
				1: arb_resp_b = 1;
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
			if (cache_read_a) next_state = read_a;
			else if (cache_read_b) next_state = read_b;
			else if (cache_write_b) next_state = write_b;
			else next_state = idle;
		end

		read_a: next_state = reading;
		read_b: next_state = reading;
		write_b: next_state = writing;

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

endmodule : L1_arbiter
