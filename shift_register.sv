module shift_register #(
	parameter width = 32,
	parameter entries = 4,
	parameter size = 2 ** entries
)
(
	input clk,
	input logic [width-1:0] in,
	input logic shift,
	input logic load,
	output logic error,
	output logic [width-1:0] out
);

logic [width-1:0] data [size];
logic valid [size];

initial begin
	for(int i = 0; i < size; i++)
	begin
		valid[i] = 0;
		data[i] = 0;
	end
end

assign error = valid[size-1];

always_ff @(posedge clk)
begin
	if(shift)
	begin
		out = data[0];
		for(int i = 1; i < size; i++)
		begin
			valid[i-1] = valid[i];
			data[i-1] = data[i];
		end
	end
	if(load)
	begin
		for(int i = 0; i < size; i++)
		begin
			if(valid[i] == 0)
			begin
				data[i] = in;
				valid[i] = 1;
				break;
			end
		end
	end
end

endmodule : shift_register