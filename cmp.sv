import rv32i_types::*;

module cmp
(
	input branch_funct3_t cmpop,
	input [31:0] a, b,
	output logic br_en
);

always_comb
begin
	br_en = 0;

	case (cmpop)
		beq  : // take branch if rs1 = rs2
			if (a == b) br_en = 1;
		bne  : // take branch if rs1 != rs2
			if (a != b) br_en = 1;
		blt  : // take branch if rs1 < rs2, signed
			if ($signed(a) < $signed(b)) br_en = 1;
		bge  : // take branch if rs1 >= rs2, signed
			if ($signed(a) >= $signed(b)) br_en = 1;
		bltu : // take branch if rs1 < rs2, unsigned
			if (a < b) br_en = 1;
		bgeu : // take branch if rs1 >= rs2, unsigned
			if (a >= b) br_en = 1;
	endcase
end

endmodule : cmp
