import rv32i_types::*;

module L2_cache #(
	parameter s_offset = 5,
   parameter s_index  = 3,
   parameter s_tag    = 32 - s_offset - s_index,
   parameter s_mask   = 2**s_offset,
   parameter s_line   = 8*s_mask,
   parameter num_sets = 2**s_index
)
(
	input logic clk,
	input rv32i_word mem_addr,
	input logic mem_read,
	input logic mem_write,
	input rv32i_word mem_wdata,
	output rv32i_word mem_rdata,
	input logic [3:0] mem_byte_enable,
	output logic mem_resp,
	
	output logic pmem_read,
	output logic pmem_write,
	output logic [s_line-1:0] pmem_wdata,
	output rv32i_word pmem_addr,
	input logic pmem_error,
	input logic [s_line-1:0] pmem_rdata,
	input logic pmem_resp
);

logic [s_tag-1:0] mem_tag;
logic [s_index-1:0] mem_index;
logic [s_tag-1:0] tag_out [4];
logic valid_out [4];
logic dirty_out[4];
logic load_valid [4];
logic load_dirty_hit [4];
logic load_dirty_miss [4];
logic load_dirty [4];
logic load_tag [4];
logic [s_mask-1:0] load_line [4];
logic dirty_in;
logic [2:0] lru_in_t, lru_out_t;
logic [1:0] lru_out,lru_in;
logic [s_line-1:0] line_out [4];
logic read_all;
logic [s_mask-1:0] write_en;
logic [1:0] line_write_mux_sel;
logic [s_line-1:0] line_datain;
logic [1:0] lru_translated;
logic [1:0] pmem_addr_sel;
logic lru_load;
logic hit [4];
logic update;
logic [s_mask-1:0] mem_byte_enable256;
logic [s_line-1:0] mem_rdata256, mem_wdata256;
logic hit_all;
logic [1:0] load_hit_sel;

//logic [s_offset-1:0] mem_offset;

assign hit_all = hit[0] || hit[1] || hit[2] || hit[3];
assign hit[0] = valid_out[0] && (mem_tag == tag_out[0]);
assign hit[1] = valid_out[1] && (mem_tag == tag_out[1]);
assign hit[2] = valid_out[2] && (mem_tag == tag_out[2]);
assign hit[3] = valid_out[3] && (mem_tag == tag_out[3]);

assign mem_tag = mem_addr[31:s_tag];
assign mem_index = mem_addr[s_offset + s_index - 1:s_offset];

assign read_all = mem_read ^ mem_write;

assign pmem_read = ((hit_all == 0) && mem_read) ||((hit_all == 0) && mem_write && (dirty_out[lru_out] == 0));
assign pmem_write = ((hit_all == 0) && (mem_read == 1) && (dirty_out[lru_out] == 1));
assign update = pmem_resp && pmem_read;

assign pmem_wdata = line_out[lru_out];
assign pmem_addr_sel = (pmem_write << 1) + pmem_read;
assign mem_resp = (pmem_read == 0) && (pmem_write == 0);

assign line_write_mux_sel = (update << 1) + (hit_all && mem_write);
assign lru_load = hit_all;


//associativity is 4

// probably need to generalize bus adapter if we want to make lines bigger
bus_adapter adapter
(
    .mem_wdata256,
    .mem_rdata256,
    .mem_wdata(mem_wdata),
    .mem_rdata,
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256,
    .address(mem_addr)
);

array #(.s_index(s_index), .width(1)) valid [4]
(
	.clk,
	.read(read_all),
	.load(load_valid),
	.index(mem_index),
	.datain(1'b1),
	.dataout(valid_out)
);

load_array valid_load
(
	.sel(lru_out),
	.load(update),
	.load_out(load_valid)
);

array #(.s_index(s_index), .width(1)) dirty [4]
(
	.clk,
	.read(read_all),
	.load(load_dirty),
	.index(mem_index),
	.datain(dirty_in),
	.dataout(dirty_out)
);

load_array dirty_load_miss
(
	.sel(lru_out),
	.load(pmem_resp && pmem_write),
	.load_out(load_dirty_miss)
);

lru_one_hot_mux #(.width(2)) hit_mux
(
	.sel(hit),
	.a(2'b00),
	.b(2'b01),
	.c(2'b10),
	.d(2'b11),
	.f(load_hit_sel)
);

load_array dirty_load_hit
(
	.sel(load_hit_sel),
	.load(mem_write),
	.load_out(load_dirty_hit)
);

mux2 #(.width(1)) load_mux [4]
(
	.sel(hit_all),
	.a(load_dirty_miss),
	.b(load_dirty_hit),
	.f(load_dirty)
);

mux2 #(.width(1)) dirty_in_mux 
(
	.sel(hit_all),
	.a(1'b0),
	.b(mem_write),
	.f(dirty_in)
);


array #(.s_index(s_index), .width(s_tag)) tag [4]
(
	.clk,
	.read(read_all),
	.load(load_tag),
	.index(mem_index),
	.datain(mem_tag),
	.dataout(tag_out)
);

load_array tag_load
(
	.sel(lru_out),
	.load(1'b1),
	.load_out(load_tag)
);

lru_logic lru_logic
(
	.hit_all(hit_all),
	.hit(hit),
	.lru_in(lru_in_t),
	.lru_out(lru_out_t)
);

translate_lru translated_out
(
	.lru_in(lru_in_t),
	.lru_out(lru_out)
);

translate_lru translated_in
(
	.lru_in(lru_out_t),
	.lru_out(lru_in)
);

array #(.s_index(s_index), .width(3)) lru
(
	.clk,
	.read(read_all),
	.load(lru_load), // load when hit from stage two regs or  pmem_read gives response
	.index(mem_index),
	.datain(lru_out_t),
	.dataout(lru_in_t)
);


mux4 #(.width(s_mask)) line_write_mux
(
	.sel(line_write_mux_sel),
	.a({s_mask{1'b0}}),
	.b(mem_byte_enable256), // comes from byte enable
	.c({s_mask{1'b1}}),
	.d({s_mask{1'bz}}),
	.f(write_en)
);

mux4 #(.width(s_line)) line_data_in_mux
(
	.sel(line_write_mux_sel),
	.a({s_line{1'bz}}),
	.b(mem_wdata256), // comes from wdata
	.c(pmem_rdata),
	.d({s_line{1'bz}}),
	.f(line_datain)
);

data_array #(.s_offset(s_offset), .s_index(s_index)) line [4]
(
	.clk,
	.read(hit), // read at same time hit
	.write_en(load_line),
	.index(mem_index),
	.datain(line_datain),
	.dataout(line_out)
);

load_array #(.width(s_mask)) line_load
(
	.sel(lru_out),
	.load(write_en),
	.load_out(load_line)
);


lru_one_hot_mux #(.width(s_line)) line_data_out_mux
(
	.sel(hit),
	.a(line_out[0]),
	.b(line_out[1]),
	.c(line_out[2]),
	.d(line_out[3]),
	.f(mem_rdata256) // not connected to anything should go out to cpu
);

mux4 pmem_address_mux
(
	.sel(pmem_addr_sel),
	.a({32{1'bz}}),
	.b({{mem_addr[31:s_offset]},{s_offset{1'b0}}}),
	.c({{tag_out[lru_out]},{mem_index},{s_offset{1'b0}}}),
	.d({32{1'bz}}),
	.f(pmem_addr)
);




endmodule : L2_cache