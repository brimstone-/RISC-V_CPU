import rv32i_types::*;

module control_rom
(
	input rv32i_opcode opcode,
   input [31:0] s_imm,
	input [2:0] funct3,
	input [6:0] funct7,
	output rv32i_control_word ctrl
);

always_comb
begin
	/* Default assignments */
	ctrl.opcode = opcode;
	ctrl.load_regfile = 1'b0;
	ctrl.aluop = alu_ops'(funct3);
	ctrl.cmpop = branch_funct3_t'(funct3);
	ctrl.mem_byte_enable = 4'b1111;

	ctrl.regfilemux_sel = 3'b000;
	ctrl.pcmux_sel = 1'b0;
	ctrl.alumux1_sel = 1'b0;
	ctrl.alumux2_sel = 3'b000;
	ctrl.cmpmux_sel = 1'b0;

	ctrl.write = 1'b0;
	//ctrl.read_a = 1'b0; //i think this is always one for cp1
	ctrl.read_b = 1'b0;
	
	/* Assign control signals based on opcode */
	case(opcode)
		op_lui: begin
			ctrl.load_regfile = 1;
			ctrl.regfilemux_sel = 2;
		end

		op_auipc: begin
			ctrl.aluop = alu_add;
			ctrl.alumux1_sel = 1;
			ctrl.alumux2_sel = 1;
		end

		op_jal: begin
			ctrl.load_regfile = 1;
			ctrl.regfilemux_sel = 4;
			//ctrl.pcmux_sel = 1; // fetch stage pcmux
			ctrl.alumux1_sel = 1;
			ctrl.alumux2_sel = 5;
			ctrl.aluop = alu_add;
		end

		op_jalr: begin
			ctrl.load_regfile = 1;
			ctrl.regfilemux_sel = 4;
			//ctrl.pcmux_sel = 1; // fetch stage pcmux
			ctrl.alumux1_sel = 0;
			ctrl.alumux2_sel = 0;
			ctrl.aluop = alu_add;
		end

		op_br: begin
      //ctrl.pcmux_sel = br_en;
			ctrl.alumux1_sel = 1;
			ctrl.alumux2_sel = 2;
			ctrl.aluop = alu_add;
		end

		op_load: begin
      	// do we have a rmask?
			ctrl.aluop = alu_add;
			ctrl.regfilemux_sel = 3;
			ctrl.load_regfile = 1;

      	case(load_funct3_t'(funct3))
             lh, lb, lh: ctrl.read_b = 1;
				 default: ;
        endcase 
        ctrl.aluop = alu_add;
		end

		op_store: begin
        ctrl.alumux2_sel = 3;
        ctrl.aluop = alu_add;
        ctrl.write = 1;
        ctrl.load_regfile = 1;
        case(store_funct3_t'(funct3))
            sb  : begin
              case(s_imm[1:0])
                2'b00 : ctrl.mem_byte_enable = 4'b0001;
                2'b01 : ctrl.mem_byte_enable = 4'b0010;
                2'b10 : ctrl.mem_byte_enable = 4'b0100;
                2'b11 : ctrl.mem_byte_enable = 4'b1000;
                default : ctrl.mem_byte_enable = 4'b1111;
              endcase
            end
            sh  : begin
              case(s_imm[1:0])
                2'b00 : ctrl.mem_byte_enable = 4'b0011;
                2'b10 : ctrl.mem_byte_enable = 4'b1100;
                default : ctrl.mem_byte_enable = 4'b1111;
              endcase
            end
            sw  : ctrl.mem_byte_enable = 4'b1111;
            default : ctrl.mem_byte_enable = 4'bxxxx;
        endcase
		end

		op_imm: begin
			ctrl.load_regfile = 1;

			case (arith_funct3_t'(funct3))
				slt: begin
					ctrl.cmpop = blt; // blt for SLTI ,bltu for SLTIU
					ctrl.regfilemux_sel = 1;
					ctrl.cmpmux_sel = 1; 
				end

				sltu: begin
					ctrl.cmpop = bltu; // blt for SLTI ,bltu for SLTIU
					ctrl.regfilemux_sel = 1;
					ctrl.cmpmux_sel = 1; 
			  end

				sr: begin
					if (funct7 == 7'b0100000) begin
						ctrl.aluop = alu_sra; // if funct7's fifth bit is 1, SRAI
					end else begin
						ctrl.aluop = alu_srl; // otherwise it's SRLI
					end
				end

				default: begin
					ctrl.aluop = alu_ops'(funct3);
				end
			endcase
		end

		op_reg: begin
			ctrl.load_regfile = 1;
			ctrl.alumux1_sel = 0;
			ctrl.alumux2_sel = 4;
			
			case (arith_funct3_t'(funct3))
				add: begin // ADD/SUB same code, case on funct7
					if (funct7 == 7'b0100000) begin
						ctrl.aluop = alu_sub;
					end else begin
						ctrl.aluop = alu_add;
					end
				end

				slt: begin
					ctrl.cmpop = blt;
					ctrl.regfilemux_sel = 1;
					ctrl.cmpmux_sel = 0;
				end
					
				sltu: begin
					ctrl.cmpop = bltu;
					ctrl.regfilemux_sel = 1;
					ctrl.cmpmux_sel = 0;
				end

				sr: begin // SRL/SRA same code, case on funct7
					if (funct7 ==  7'b0100000) begin
						ctrl.aluop = alu_sra; // either sra
					end else begin
						ctrl.aluop = alu_srl; // or srl
					end
				end

				default: begin // everything else has a unique code
					ctrl.aluop = alu_ops'(funct3);
				end

			endcase
		end

		//op_csr: ; // not used

		default: begin
			ctrl = 0;   /* Unknown opcode, set control word to zero */
		end

	endcase
end

endmodule : control_rom
