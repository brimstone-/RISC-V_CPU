module translate_lru
(
	input logic [2:0] lru_in,
	output logic [1:0] lru_out
);

always_comb
begin
	case(lru_in)
		3'b000:
			lru_out = 0;
		3'b001:
			lru_out = 1;
		3'b010:
			lru_out = 0;
		3'b011:
			lru_out = 1;
		3'b100:
			lru_out = 2;
		3'b101:
			lru_out = 2;
		3'b110:
			lru_out = 3;
		3'b111:
			lru_out = 3;
		default:
			lru_out = 2'bzz;
	endcase

end

endmodule : translate_lru