import rv32i_types::*;
/* Combinational IR */
module ir
(
    input [31:0] in,
    output [2:0] funct3,
    output [6:0] funct7,
    output rv32i_opcode opcode,
    output [31:0] i_imm,
    output [31:0] s_imm,
    output [31:0] b_imm,
    output [31:0] u_imm,
    output [31:0] j_imm,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd
);

assign funct3 = in[14:12];
assign funct7 = in[31:25];
assign opcode = rv32i_opcode'(in[6:0]);
assign i_imm = {{21{in[31]}}, in[30:20]};
assign s_imm = {{21{in[31]}}, in[30:25], in[11:7]};
assign b_imm = {{20{in[31]}}, in[7], in[30:25], in[11:8], 1'b0};
assign u_imm = {in[31:12], 12'h000};
assign j_imm = {{12{in[31]}}, in[19:12], in[20], in[30:21], 1'b0};
assign rs1 = in[19:15];
assign rs2 = in[24:20];
assign rd = in[11:7];

endmodule : ir
