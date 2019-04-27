import rv32i_types::*;

module L2_arbiter
(
	input clk,

	// from/to L2
	input L2_read,
	input rv32i_word L2_addr,
	output logic [255:0] L2_rdata,
	output logic L2_arb_resp,
	
	// ewb
	output logic arb_ewb_resp,
	input ewb_write,
	input [255:0] ewb_wdata,
	input rv32i_word ewb_addr,
	
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
logic load_type;
logic [1:0] transaction_type_in, transaction_type_out;

assign L2_rdata = rdata_out;

mux2 addr_mux
(
	.sel(addr_mux_sel),
	.a(L2_addr),
	.b(ewb_addr),
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
	.in(ewb_wdata),
	.out(pmem_wdata)
);

/*
	0 = demand read
	1 = prefetch
	2 = ewb write
*/
register #(.width(2)) transaction_type_reg
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
	transaction_type_in = 2'b0;

	pmem_read = 0;
	pmem_write = 0;

	L2_arb_resp = 0;
	arb_ewb_resp = 0;

	case(state)
		idle: ;
		demand_read: begin
			addr_mux_sel = 0;
			load_addr = 1;
			load_type = 1;
			transaction_type_in = 0;
		end
		demand_write: begin
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
				0: L2_arb_resp = 1;
				1: arb_ewb_resp = 1;
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
			if (L2_read) next_state = demand_read;
			else if (ewb_write) next_state = demand_write;
			else next_state = idle;
		end

		demand_read: next_state = reading;
		demand_write: next_state = writing;

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
