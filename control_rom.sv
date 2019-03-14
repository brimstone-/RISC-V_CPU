import rv32i_types::*;

module control_rom
(
	input rv32i_opcode opcode,
	/* ... other inputs ... */
	output rv32i_control_word ctrl
);

always_comb
begin
	/* Default assignments */
	ctrl.opcode = opcode;
	ctrl.load_regfile = 1’b0;
	
	/* ... other defaults ... */
	
	/* Assign control signals based on opcode */
	case(opcode)
		op_auipc: begin
			ctrl.aluop = alu_add;
		end
		/* ... other opcodes ... */
		default: begin
			ctrl = 0;   /* Unknown opcode, set control word to zero */
		end
	endcase
end

endmodule : control_rom
