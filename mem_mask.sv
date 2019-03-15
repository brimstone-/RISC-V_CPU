import rv32i_types::*;

module mem_mask
(
	input [2:0] funct3,
	input rv32i_opcode opcode,
	input rv32i_word mdrreg_out,
	input rv32i_word rs1_out,
	input rv32i_word rs2_out,
	input rv32i_word i_imm,
	input rv32i_word s_imm,
	output logic [31:0] out
);

load_funct3_t load_funct3;
assign load_funct3 = load_funct3_t'(funct3);

store_funct3_t store_funct3;
assign store_funct3 = store_funct3_t'(funct3);

rv32i_word load_addr;
assign load_addr = rs1_out + i_imm;

rv32i_word store_addr;
assign store_addr = rs1_out + s_imm;

always_comb
begin
	case(opcode)
		op_load: begin
			case(load_funct3)
				lb :
					case(load_addr[1:0])
						2'b00 : out = {{24{mdrreg_out[ 7]}},mdrreg_out[ 7: 0]};
						2'b01 : out = {{24{mdrreg_out[15]}},mdrreg_out[15: 8]};
						2'b10 : out = {{24{mdrreg_out[23]}},mdrreg_out[23:16]};
						2'b11 : out = {{24{mdrreg_out[31]}},mdrreg_out[31:24]};
						default : out = 32'hxxxxxxxx;
					endcase
				lh :
					case(load_addr[1:0])
						2'b00 : out = {{16{mdrreg_out[15]}},mdrreg_out[15:0]};
						2'b10 : out = {{16{mdrreg_out[31]}},mdrreg_out[31:16]};
						default : out = 32'hxxxxxxxx;
					endcase
				lw : out = mdrreg_out;
				lbu :
					case(load_addr[1:0])
						2'b00 : out = {{24{1'b0}},mdrreg_out[7 :0]};
						2'b01 : out = {{24{1'b0}},mdrreg_out[15: 8]};
						2'b10 : out = {{24{1'b0}},mdrreg_out[23:16]};
						2'b11 : out = {{24{1'b0}},mdrreg_out[31:24]};
						default : out = 32'hxxxxxxxx;
					endcase
				lhu :
					case(load_addr[1:0])
						2'b00 : out = {{16{1'b0}},mdrreg_out[15:0]};
						2'b10 : out = {{16{1'b0}},mdrreg_out[31:16]};
						default : out = 32'hxxxxxxxx;
					endcase
			endcase
		end
		
		op_store: begin
			case(store_funct3)
				sb : begin
					case(store_addr[1:0])
						2'b00 : out = rs2_out;
						2'b01 : out = {rs2_out[23:0],{ 8{1'b0}}};
						2'b10 : out = {rs2_out[15:0],{16{1'b0}}};
						2'b11 : out = {rs2_out[ 7:0],{24{1'b0}}};
						default : out = 32'hxxxxxxxx;
					endcase
				end
				sh : begin
					case(store_addr[1:0])
						2'b00 : out = rs2_out;
						2'b10 : out = {rs2_out[15:0],{16{1'b0}}};
						default : out = 32'hxxxxxxxx;
					endcase
				end
				sw : out = rs2_out;
			endcase
		end
		
		default : out = rs2_out;
	endcase
end

endmodule : mem_mask