module load_array #(
	parameter width = 1
)

(
	input logic [1:0] sel,
	input logic [width-1:0] load,
	output logic [width-1:0] load_out [4]
);

always_comb
begin
	for(int i = 0; i < 4; i++)
	begin
		load_out[i] = 0;
	end
	load_out[sel] = load;
end

endmodule : load_array