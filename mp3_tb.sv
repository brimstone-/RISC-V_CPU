import rv32i_types::*;

module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk;

/* Port A */
logic read_a;
logic [31:0] address_a;
logic resp_a;
logic [31:0] rdata_a;

/* Port B */
logic read_b;
logic write;
logic [3:0] wmask;
logic [31:0] address_b;
logic [31:0] wdata;
logic resp_b;
logic [31:0] rdata_b;

initial
begin
    clk = 0;
end

/* Clock generator */
always #5 clk = ~clk;

//assign registers = dut.cpu.datapath.regfile.data;
//assign data0 = dut.cache.datapath.line[0].data;
//assign data1 = dut.cache.datapath.line[1].data;
//assign tags0 = dut.cache.datapath.tag[0].data;
//assign tags1 = dut.cache.datapath.tag[1].data;

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

mp3 dut
(
	.*
);

magic_memory_dp megic_mem
(
    .clk,

    /* Port A */
    .read_a,
    .address_a,
    .resp_a,
    .rdata_a,

    /* Port B */
    .read_b,
    .write,
    .wmask,
    .address_b,
    .wdata,
    .resp_b,
    .rdata_b
);

endmodule : mp3_tb
