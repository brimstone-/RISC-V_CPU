import rv32i_types::*;

module branch_target_buffer #(parameter s_index = 5, parameter s_btb = 2**s_index) 
(
	input clk,
	
	input rv32i_word fetch_pc, // from fetch, to check hit
	output rv32i_word target, // to fetch
	output hit, // to fetch
	
	input pcmux_sel,
	
	input rv32i_word alu_out, // from execute, to fill data
	input rv32i_word exec_pc // from execute, to fill tag
);

logic load;
logic [s_index-1:0] fetch_index, exec_index;
rv32i_word tag [s_btb];
rv32i_word data [s_btb];

initial begin
	for (int i = 0; i < s_btb; i++) begin
		tag[i] = {32{1'b0}};
		data[i] = {32{1'b0}};
	end
end

assign load = pcmux_sel;
assign fetch_index = fetch_pc[s_index+1:2];
assign exec_index = exec_pc[s_index+1:2];

assign hit = tag[fetch_index] == fetch_pc;

always_ff @(posedge clk) begin
	if (load) begin
		tag[exec_index] <= exec_pc;
		data[exec_index] <= alu_out;
	end

	if (hit)
		target <= data[fetch_index];
	else
		target <= {32{1'bx}};
end

endmodule : branch_target_buffer
