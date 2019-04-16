import rv32i_types::*;

module external_write_buffer
(
	input clk,

	input [255:0] cache_wdata_b, // wdata from dcache
	input cache_read_b, // signal from dcache
	input cache_write_b, // signal from dcache
	output logic ewb_resp_b, // resp going back to dcache
	input [31:0] cache_addr_b, // addr from dcache
	
	output logic ewb_write, // write signal going to arb
	output rv32i_word ewb_addr, // address going to arb
	output logic [255:0] ewb_wdata, // wdata going to arb
	input arb_ewb_resp // resp from arb
);

logic load;

register #(.width(256)) wdata_reg 
(
	.clk,
	.load,
	.reset(1'b0),
	.in(cache_wdata_b),
	.out(ewb_wdata)
);

register #(.width(32)) addr_reg
(
	.clk,
	.load,
	.reset(1'b0),
	.in(cache_addr_b),
	.out(ewb_addr)
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
	ewb_resp_b = 0;
	ewb_write = 0;
	load = 0;
	
	case(state)
		idle: ;
		store: begin
			load = 1;
			ewb_resp_b = 1;
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
			if (cache_write_b) next_state = store;
			else next_state = idle;
		end
		store: begin
			next_state = waiting;
		end
		waiting: begin
			if (cache_read_b) next_state = waiting;
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
