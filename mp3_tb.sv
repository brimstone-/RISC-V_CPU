import rv32i_types::*;

module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk;

logic pmem_read;
logic pmem_write;
rv32i_word pmem_address;
logic [255:0] pmem_wdata;
logic pmem_resp;
logic pmem_error;
rv32i_word pmem_rdata;

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

physical_memory pmem
(
    .clk,
    .read(pmem_read),
    .write(pmem_write),
    .address(pmem_address),
    .wdata(pmem_wdata),
    .resp(pmem_resp),
    .error(pmem_error),
    .rdata(pmem_rdata)
);

endmodule : mp3_tb
