import rv32i_types::*;

module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk;
logic pmem_resp;
logic pmem_read;
logic pmem_write;
logic [31:0] pmem_address;
logic [255:0] pmem_wdata;
logic [255:0] pmem_rdata;


logic [31:0] reg_in;
logic [31:0] pc;
logic [31:0] cache_out;
logic ld_regfile;
logic [4:0] rd;
stage_regs regs;
//logic [15:0] errcode;

///* autograder signals */
//logic [255:0] write_data;
//logic [27:0] write_address;
//logic write;
//logic halt;
//logic sm_error;
//logic pm_error;
//logic [31:0] registers [32];
//logic [255:0] data0 [8];
//logic [255:0] data1 [8];
//logic [23:0] tags0 [8];
//logic [23:0] tags1 [8];
//logic [63:0] order;

initial
begin
    clk = 0;
    //order = 0;
    //halt = 0;
end

/* Clock generator */
always #5 clk = ~clk;

//assign registers = dut.cpu.datapath.regfile.data;
//assign data0 = dut.cache.datapath.line[0].data;
//assign data1 = dut.cache.datapath.line[1].data;
//assign tags0 = dut.cache.datapath.tag[0].data;
//assign tags1 = dut.cache.datapath.tag[1].data;
initial
begin
	 reg_in = 32'h97;
	 pc = 32'h60;
	 ld_regfile = 0;
	 cache_out = 32'hdeadbeef;
	 rd = 3;
	 #100
	 ld_regfile = 1;
	 #20
	 ld_regfile = 0;
	 #100
	 rd = 7;
	 ld_regfile = 1;
	 #20
	 ld_regfile = 0;
	 #10
	 pc = 32'h64;
	 $finish;
end
//always @(posedge clk)
//begin
		
//    if (pmem_write & pmem_resp) begin
//        write_address = pmem_address[31:5];
//        write_data = pmem_wdata;
//        write = 1;
//    end else begin
//        write_address = 27'hx;
//        write_data = 256'hx;
//        write = 0;
//    end
//    if ((|errcode) || pm_error || sm_error || (dut.cpu.load_pc && dut.cpu.control.trap)) begin
//        halt = 1;
//        $display("Halting with error!");
//        $finish;
//    end else 
//    if (dut.cpu.load_pc & (dut.cpu.datapath.pc_out == dut.cpu.datapath.pcmux_out))
//    begin
//        halt = 1;
//        $display("Halting without error");
//        $finish;
//    end
//    if (dut.cpu.load_pc) order = order + 1;
//end
decode stage_two
(
	 .*
);
/*

mp3 dut(
    .*
);

magic_memory_dp magic_memory
(
	.*
);
*/
endmodule : mp3_tb
