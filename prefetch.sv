import rv32i_types::*;

module prefetch
(
	input clk,

	input cache_read_a,
	input rv32i_word cache_addr_a,
	output logic pre_resp_a,
	output logic [255:0] pre_rdata_a,
	
	output logic pre_read_a,
	output rv32i_word pre_addr_a,
	input [255:0] arb_pre_rdata,
	input arb_pre_resp
);

logic addr_hit;
assign addr_hit = cache_addr_a == pre_addr_a;

logic load_addr;

logic load_past_read;
logic past_read_in;
logic past_read_out;

register #(.width(256)) rdata_reg
(
	.clk,
	.load(arb_pre_resp),
	.reset(1'b0),
	.in(arb_pre_rdata),
	.out(pre_rdata_a)
);

register #(.width(32)) addr_reg
(
	.clk,
	.load(load_addr),
	.reset(1'b0),
	.in(cache_addr_a + 32'h00000020),
	.out(pre_addr_a)
);

register #(.width(1)) past_read_reg
(
	.clk,
	.load(load_past_read),
	.reset(1'b0),
	.in(past_read_in),
	.out(past_read_out)
);

enum int unsigned {
	idle,
	hit,
	load_regs,
	waiting,
	reading,
	finish
} state, next_state;

always_comb
begin : state_actions
	/* Default output assignments */
	load_addr = 0;
	load_past_read = 0;
	past_read_in = 0;
	
	pre_read_a = 0;
	pre_resp_a = 0;
	
	case(state)
		idle: ;
		hit: begin
			pre_resp_a = 1;
			load_addr = 1;
			load_past_read = 1;
			past_read_in = 1;
		end
		load_regs: begin
			load_addr = 1;
			load_past_read = 1;
			past_read_in = 1;
		end
		waiting: ;
		reading: begin
			pre_read_a = 1;
			// rdata reg loaded by mem resp
		end
		finish: begin
			pre_resp_a = 1;
			load_past_read = 1;
			past_read_in = 0;
		end

		default: ;
	endcase
end

always_comb
begin : next_state_logic
	next_state = state;
	case(state)
		idle: begin
			if (cache_read_a & addr_hit) next_state = hit;
			else if (cache_read_a & ~addr_hit) next_state = load_regs;
			else if (past_read_out) next_state = reading;
			else next_state = idle;
		end
		hit: begin
			next_state = idle;
		end
		load_regs: next_state = waiting;
		waiting: begin
			if (cache_read_a) next_state = waiting;
			else next_state = reading;
		end
		reading: begin
			if (arb_pre_resp) next_state = finish;
			else next_state = reading;
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

endmodule : prefetch
