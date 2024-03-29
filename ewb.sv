import rv32i_types::*;

module external_write_buffer
(
	input clk,

	input [255:0] cache_wdata, // wdata from dcache
	input cache_read, // signal from dcache
	input cache_write, // signal from dcache
	output logic ewb_resp, // resp going back to dcache
	input [31:0] cache_addr, // addr from dcache
	
	output logic ewb_write, // write signal going to arb
	output rv32i_word ewb_addr, // address going to arb
	output logic [255:0] ewb_wdata, // wdata going to arb
	input arb_ewb_resp, // resp from arb
	
	output logic [31:0] ewb_writes_count,
	input ewb_writes_reset
);

logic load;
logic [31:0] ewb_writes_out;

register #(.width(256)) wdata_reg 
(
	.clk,
	.load,
	.reset(1'b0),
	.in(cache_wdata),
	.out(ewb_wdata)
);

register #(.width(32)) addr_reg
(
	.clk,
	.load,
	.reset(1'b0),
	.in(cache_addr),
	.out(ewb_addr)
);

assign ewb_writes_count = ewb_writes_out;
register #(.width(32)) ewb_writes_reg
(
	.clk,
	.load,
	.reset(ewb_writes_reset),
	.in(ewb_writes_out + 1),
	.out(ewb_writes_out)
);

enum int unsigned {
	idle,
	store,
	waiting,
	write
} state, next_state;

always_comb
begin : state_actions
	/* Default output assignments */
	ewb_resp = 0;
	ewb_write = 0;
	load = 0;
	
	case(state)
		idle: ;
		store: begin
			load = 1;
			ewb_resp = 1;
		end
		waiting: ;
		write: begin
			ewb_write = 1;
		end
		default: ;
	endcase
end

always_comb
begin : next_state_logic
	next_state = state;
	case(state)
		idle: begin
			if (cache_write) next_state = store;
			else next_state = idle;
		end
		store: begin
			next_state = waiting;
		end
		waiting: begin
			if (cache_read) next_state = waiting;
			else next_state = write;
		end
		write: begin
			if (arb_ewb_resp) next_state = idle;
			else next_state = write;
		end
		default: next_state = idle;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
	/* Assignment of next state on clock edge */
	state <= next_state;
end

endmodule : external_write_buffer
