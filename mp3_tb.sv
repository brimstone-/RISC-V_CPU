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
    order = 0;
    halt = 0;
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


mp3 dut(
    .*
);

magic_memory_dp magic_memory
(
	.*
);

endmodule : mp3_tb
