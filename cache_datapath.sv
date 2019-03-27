module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,

	input [31:0] mem_address,
	input [31:0] mem_wdata,
	input [3:0] mem_byte_enable,

	input arrays_read,
	
	input dirty_load [2], dirty_in [2],
	input valid_load [2], valid_in [2],
	input tag_load [2],
	
	input pmem_addr_mux_sel,
	input data_array_mux_sel [2],
	input [1:0] mem_mask_mux_sel [2],

	input [255:0] pmem_rdata,
	
	output logic lru_out,
	output logic hit [2],
	output logic dirty_out [2],
	output logic valid_out [2],
	output logic [31:0] mem_rdata,
	output logic [255:0] pmem_wdata,
	output logic [31:0] pmem_address
);

logic [s_tag-1:0] tag_bits;
assign tag_bits = mem_address[31:8];

logic [s_index-1:0] index;
assign index = mem_address[7:5];

//logic [s_offset-1:0] offset;
//assign offset = mem_address[4:0];

logic [s_tag-1:0] tag_out [2];

logic [s_tag-1:0] tag_mux_out;

logic [31:0] mem_mask_mux_out [2];
logic [s_line-1:0] line_out [2];

logic [31:0] zeros;
logic [31:0] ones;
assign zeros = {32{1'b0}};
assign ones = {32{1'b1}};

logic comp [2];
assign comp[0] = tag_out[0] == tag_bits;
assign comp[1] = tag_out[1] == tag_bits;

assign hit[0] = comp[0] & valid_out[0];
assign hit[1] = comp[1] & valid_out[1];

logic hit_either;
assign hit_either = hit[0] | hit[1];

logic [255:0] data_array_mux_out [2];

logic [255:0] mem_wdata256 [2];
logic [31:0] mem_byte_enable256 [2];
logic [31:0] bus_adapter_out [2];

array LRU
(
    .clk,
    .read(arrays_read),
    .load(hit_either),
    .index(index),
    .datain(hit[0]),
    .dataout(lru_out)
);

array dirty_bit [2]
(
    .clk,
    .read(arrays_read),
    .load(dirty_load),
    .index(index),
    .datain(dirty_in),
    .dataout(dirty_out)
);

array valid_bit [2]
(
    .clk,
    .read(arrays_read),
    .load(valid_load),
    .index(index),
    .datain(valid_in),
    .dataout(valid_out)
);

array #(.width(s_tag)) tag [2]
(
    .clk,
    .read(arrays_read),
    .load(tag_load),
    .index(index),
    .datain(tag_bits),
    .dataout(tag_out)
);

data_array line [2]
(
    .clk,
    .read(arrays_read),
    .write_en(mem_mask_mux_out),
    .index(index),
    .datain(data_array_mux_out),
    .dataout(line_out)
);

mux4 mem_mask_mux [2]
(
	.sel(mem_mask_mux_sel),
	.a(zeros),
	.b(ones),
	.c(mem_byte_enable256),
	.d(),
	.f(mem_mask_mux_out)
);

mux2 #(.width(256)) writeback_mux
(
	.sel(lru_out),
	.a(line_out[0]),
	.b(line_out[1]),
	.f(pmem_wdata)
);

mux2_1hot #(.width(32)) data_out_mux
(
	.sel({hit[0],hit[1]}),
	.a(bus_adapter_out[0]),
	.b(bus_adapter_out[1]),
	.f(mem_rdata)
);

mux2 #(.width(256)) data_array_mux [2]
(
	.sel(data_array_mux_sel),
	.a(pmem_rdata),
	.b(mem_wdata256),
	.f(data_array_mux_out)
);

mux2 #(.width(24)) tag_mux
(
	.sel(lru_out),
	.a(tag_out[0]),
	.b(tag_out[1]),
	.f(tag_mux_out)
);

mux2 #(.width(32)) pmem_addr_mux
(
	.sel(pmem_addr_mux_sel),
	.a(mem_address),
	.b({tag_mux_out, index, 5'b00000}),
	.f(pmem_address)
);

bus_adapter bus_adapter [2]
(
    .mem_wdata256(mem_wdata256),
    .mem_rdata256(line_out),
    .mem_wdata(mem_wdata),
    .mem_rdata(bus_adapter_out),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(mem_byte_enable256),
    .address(mem_address)
);

endmodule : cache_datapath
