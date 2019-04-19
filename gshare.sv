import rv32i_types::*;

module gshare #(parameter sr_size = 3, parameter bht_size = 2**sr_size)(
	input logic clk,

	// fetch signals
	input rv32i_word fetch_pc,
	output logic [sr_size-1:0] bhr_out,     // branch history register state to exec state -> *register*  
	output logic taken,	                    // ouput taken prediction 

	// exec signals 
	input rv32i_opcode opcode,
	input rv32i_word exec_pc,
	input logic pcmux_sel,                  // shows was BR taken in EXEC - use to update BHR as up/down  
	input logic [sr_size-1:0] bhr_in        // old BHR we use to access PHT 
); 

// PHT: 00 SN | 01 WN | 10 WT | 11 ST
logic [1:0] branch_history_table [bht_size];
logic [2:0] reg_out, bht_index, prev_bht_index;    // access pht (size 3: 2^3 = 8 = bht_size)
logic branch;

initial begin
	reg_out = 3'b00;
	
	for(int i = 0; i < bht_size; i++) begin
		branch_history_table[i] = 2'b01;       // initalize all pattern histoy table to WNT
	end
end

register #(.width(sr_size)) branch_history_register
(
	.clk,
	.load(branch),
	.reset(1'b0),
	.in({reg_out[1:0], pcmux_sel}),
	.out(bhr_out)
);

assign bht_index = fetch_pc[4:2] ^ bhr_out;
assign prev_bht_index = exec_pc[4:2] ^ bhr_in;
assign branch = (opcode == op_br | opcode == op_jal | opcode == op_jalr);


always_ff @(posedge clk) begin
	if(branch) begin
		if (pcmux_sel) begin
			case (branch_history_table[prev_bht_index])
			 2'b00: branch_history_table[prev_bht_index] = 2'b01;
			 2'b01: branch_history_table[prev_bht_index] = 2'b10;
			 2'b10: branch_history_table[prev_bht_index] = 2'b11;
			 2'b11: branch_history_table[prev_bht_index] = 2'b11;
			endcase
		end
		else begin
			case (branch_history_table[prev_bht_index])
			 2'b00: branch_history_table[prev_bht_index] = 2'b00;
			 2'b01: branch_history_table[prev_bht_index] = 2'b00;
			 2'b10: branch_history_table[prev_bht_index] = 2'b01;
			 2'b11: branch_history_table[prev_bht_index] = 2'b10;
			endcase
		end
	end
	taken = branch_history_table[bht_index][1];
end 

endmodule: gshare
