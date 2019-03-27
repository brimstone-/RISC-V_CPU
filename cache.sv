module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	input mem_read,
	input mem_write,
	input [31:0] mem_address,
	input [31:0] mem_wdata,
	input [3:0] mem_byte_enable,

	output logic mem_resp,
	output logic [31:0] mem_rdata,
	
	input pmem_resp,
	input pmem_error,
	input [255:0] pmem_rdata,
	
	output logic pmem_read,
	output logic pmem_write,
	output logic [31:0] pmem_address,
	output logic [255:0] pmem_wdata
);

logic lru_read, lru_out;
logic hit [2];
logic arrays_read;
logic dirty_load [2];
logic dirty_out [2];
logic dirty_in [2];
logic valid_load [2];
logic valid_out [2];
logic valid_in [2];
logic tag_load [2];
logic pmem_addr_mux_sel;
logic data_array_mux_sel [2];
logic [1:0] mem_mask_mux_sel [2];

cache_control control
(
	.clk,
	.lru_out,
	.hit,
	.dirty_out,
	.valid_out,
	.mem_read,
	.mem_write,
	.mem_resp,
	.pmem_resp,
	.arrays_read,
	.dirty_load,
	.dirty_in,
	.valid_load,
	.valid_in,
	.tag_load,
	.pmem_addr_mux_sel,
	.data_array_mux_sel,
	.mem_mask_mux_sel,
	.pmem_read,
	.pmem_write,
	.pmem_error
);

cache_datapath datapath
(
	.clk,
	.mem_address,
	.mem_wdata,
	.mem_byte_enable,
	.arrays_read,
	.dirty_load,
	.dirty_in,
	.valid_load,
	.valid_in,
	.tag_load,
	.pmem_addr_mux_sel,
	.data_array_mux_sel,
	.mem_mask_mux_sel,
	.pmem_rdata,
	.lru_out,
	.hit,
	.dirty_out,
	.valid_out,
	.mem_rdata,
	.pmem_wdata,
	.pmem_address
);

endmodule : cache
