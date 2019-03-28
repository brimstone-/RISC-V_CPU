module cache_control (
	input clk,

	input lru_out,
	input hit [2],
	input dirty_out [2],
	input valid_out [2],
	
	input mem_read, mem_write,
	input pmem_resp,
	
	input pmem_error,

	output logic arrays_read,
	
	output logic dirty_load [2], dirty_in [2],
	output logic valid_load [2], valid_in [2],
	output logic tag_load [2],
	
	output logic pmem_addr_mux_sel,
	output logic data_array_mux_sel [2],
	output logic [1:0] mem_mask_mux_sel [2],
	
	output logic mem_resp,
	
	output logic pmem_read, pmem_write
);

enum int unsigned {
	check,
	allocate,
	writeback
} state, next_state;

always_comb
begin : state_actions
	/* Default output assignments */
	arrays_read = 1;

	dirty_load[0] = 0;
	dirty_load[1] = 0;

	dirty_in[0] = 0;
	dirty_in[1] = 0;

	valid_load[0] = 0;
	valid_load[1] = 0;

	valid_in[0] = 0;
	valid_in[1] = 0;

	tag_load[0] = 0;
	tag_load[1] = 0;
	
	pmem_addr_mux_sel = 0;
	
	data_array_mux_sel [0]= 0;
	data_array_mux_sel [1]= 0;

	mem_mask_mux_sel [0] = 0;
	mem_mask_mux_sel [1] = 0;
	
	mem_resp = 0;
	
	pmem_read = 0;
	pmem_write = 0;

	case(state)
		check : begin
			if (mem_read) begin
				if (hit[0] || hit[1]) begin
					mem_resp = 1;
				end
			end else if (mem_write) begin
				if (hit[0]) begin
					mem_resp = 1;
					dirty_load[0] = 1;
					dirty_in[0] = 1;
					data_array_mux_sel[0] = 1;
					mem_mask_mux_sel[0] = 2;
				end else if (hit[1]) begin
					mem_resp = 1;
					dirty_load[1] = 1;
					dirty_in[1] = 1;
					data_array_mux_sel[1] = 1;
					mem_mask_mux_sel[1] = 2;
				end
			end
		end
		
		allocate : begin
			pmem_read = 1;
			if (lru_out) begin
				dirty_load[1] = 1;
				dirty_in[1] = 0;
				valid_load[1] = 1;
				valid_in[1] = 1;
				tag_load[1] = 1;
				data_array_mux_sel[1] = 0;
				mem_mask_mux_sel[1] = 1;
			end else begin
				dirty_load[0] = 1;
				dirty_in[0] = 0;
				valid_load[0] = 1;
				valid_in[0] = 1;
				tag_load[0] = 1;
				data_array_mux_sel[0] = 0;
				mem_mask_mux_sel[0] = 1;
			end
		end
		
		writeback : begin
			pmem_write = 1;
			pmem_addr_mux_sel = 1;
			if (dirty_out[0]) begin
				dirty_load[0] = 1;
				dirty_in[0] = 0;
			end else if (dirty_out[1]) begin
				dirty_load[1] = 1;
				dirty_in[1] = 0;
			end
		end
		
		default: /* Do nothing */;
	endcase
end

always_comb
begin : next_state_logic
	next_state = state;
	case(state)
		check : begin
			if (hit[0] || hit[1]) begin
				next_state = check;
			end else if ((!lru_out && dirty_out[0]) || (lru_out && dirty_out[1])) begin
				next_state = writeback;
			end else begin
				next_state = allocate;
			end
		end

		allocate : begin
			if (pmem_resp) begin
				next_state = check;
			end else begin
				next_state = allocate;
			end
		end

		writeback : begin
			if (pmem_resp) begin
				next_state = check;
			end else begin
				next_state = writeback;
			end
		end

		default: next_state = check;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
	/* Assignment of next state on clock edge */
	state <= next_state;
end

endmodule : cache_control
