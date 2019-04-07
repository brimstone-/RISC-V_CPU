module lru_one_hot_mux  #(
	parameter width = 3
)

(
	input logic sel [4],
	input logic [width-1:0] a,
	input logic [width-1:0] b,
	input logic [width-1:0] c,
	input logic [width-1:0] d,
	output logic [width-1:0] f
);

always_comb
begin
	f = {width{1'bz}};
	if(sel[3])
		f = d;
	if(sel[2])
		f = c;		
	if(sel[1])
		f = b;
	if(sel[0])
		f = a;		
end


endmodule : lru_one_hot_mux 