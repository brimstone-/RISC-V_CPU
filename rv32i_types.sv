package rv32i_types;

typedef enum bit [6:0] {
    op_lui   = 7'b0110111, //load upper immediate (U type)
    op_auipc = 7'b0010111, //add upper immediate PC (U type)
    op_jal   = 7'b1101111, //jump and link (J type)
    op_jalr  = 7'b1100111, //jump and link register (I type)
    op_br    = 7'b1100011, //branch (B type)
    op_load  = 7'b0000011, //load (I type)
    op_store = 7'b0100011, //store (S type)
    op_imm   = 7'b0010011, //arith ops with register/immediate operands (I type)
    op_reg   = 7'b0110011, //arith ops with register operands (R type)
    op_csr   = 7'b1110011  //control and status register (I type)
} rv32i_opcode;

typedef enum bit [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
} branch_funct3_t;

typedef enum bit [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
} load_funct3_t;

typedef enum bit [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
} store_funct3_t;

typedef enum bit [2:0] {
    add  = 3'b000, //check bit30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check bit30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
} arith_funct3_t;

typedef enum bit [2:0] {
    alu_add = 3'b000,
    alu_sll = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor = 3'b100,
    alu_srl = 3'b101,
    alu_or  = 3'b110,
    alu_and = 3'b111
} alu_ops;

typedef enum bit [7:0] {
   icache_hit       = 8'h00,
   icache_miss      = 8'h04,
   dcache_hit       = 8'h08,
   dcache_miss      = 8'h0c,
   l2_hit           = 8'h10,
   l2_miss          = 8'h14,
   ewb_writes       = 8'h18,
   branch_total     = 8'h1c,
   branch_incorrect = 8'h20
//   prefetch_hit     = 8'h28,
//   prefetch_read    = 8'h2c
} counter_addr;

typedef struct packed {
	rv32i_opcode opcode;
	alu_ops aluop;
	logic [2:0] regfilemux_sel;
	logic load_regfile;
	branch_funct3_t cmpop;
	logic [3:0] mem_byte_enable;
	logic write;
	//logic read_a;
	logic read_b;
	logic pcmux_sel;
	logic alumux1_sel;
	logic [2:0] alumux2_sel;
	logic cmpmux_sel;
	logic [1:0] store_type;
	logic [1:0] load_type;
	logic load_unsigned;
} rv32i_control_word;

typedef struct packed {
	logic [31:0] i_imm;
	logic [31:0] s_imm;
	logic [31:0] b_imm;
	logic [31:0] u_imm;
	logic [31:0] j_imm;
	logic [4:0] rd;
	logic [31:0] rs1;
	logic [4:0] rs1_num;
	logic [31:0] rs2;
	logic [4:0] rs2_num;
	logic [31:0] pc;
	rv32i_control_word ctrl;
	logic [31:0] alu;
	logic [31:0] br;
	logic valid;
	logic [2:0] funct3;
} stage_regs;

typedef struct packed {
	logic [31:0] mem_address;
	logic [31:0] mem_byte_enable;
	logic [255:0] mem_wdata;
	logic valid;
	logic mem_write;
	logic mem_read;
} cache_regs;

typedef struct packed {
	logic [4:0] bhr;
	logic taken;
	logic [31:0] btb_address;
} predict_regs;

typedef logic [31:0] rv32i_word;
typedef logic [4:0] rv32i_reg;
typedef logic [3:0] rv32i_mem_wmask;

endpackage : rv32i_types
