import rv32i_types::*;

module p_cache #(    
	parameter s_offset = 5,
   parameter s_index  = 3,
   parameter s_tag    = 32 - s_offset - s_index,
   parameter s_mask   = 2**s_offset,
   parameter s_line   = 8*s_mask,
   parameter num_sets = 2**s_index
)
(
	input logic clk,
	input logic [31:0] mem_addr,
	
	input logic mem_read,
	input logic mem_write,
	input logic [31:0] mem_wdata,
	output logic [31:0] mem_rdata,
	input logic [3:0] mem_byte_enable,
	output logic mem_resp,
	
	input logic pmem_resp,
	output logic pmem_read,
	input logic [s_line-1:0] pmem_rdata,
	output logic [31:0] pmem_addr,
	input logic pmem_error,
	output logic [s_line-1:0] pmem_wdata,
	output logic pmem_write
	
);

logic [s_tag-1:0] tag;
logic [s_index-1:0] index;
logic read,hit,lru_load,lru_in,lru_out;

logic valid_out[2];
logic tag_load [2];
logic valid_load [2];
logic [s_tag-1:0] tag_out [2];
logic dirty_out [2];
logic dirty_in;
logic data_read [2];
logic dirty_load [2];
logic [s_mask-1:0] write_en [2];
logic [s_line-1:0] data_in [2];
logic [s_line-1:0] data_out [2];

// logic [s_offset-1:0] offset_out;

logic [s_line-1:0] mem_wdata256;
logic [s_line-1:0] mem_rdata256;
logic [s_mask-1:0] mem_byte_enable256;


assign tag = mem_addr[31:(s_index + s_offset)];
assign index = mem_addr[(s_index + s_offset-1):s_offset];
assign read = 1'b1;
// assign offset_out = mem_addr[(s_offset-1):0];

bus_adapter adapter 
(
	.mem_wdata256,
	.mem_rdata256(mem_rdata256),
	.mem_wdata,
	.mem_rdata,
	.mem_byte_enable,
	.mem_byte_enable256,
	.address(mem_addr)
);

array #(.s_index(s_index), .width(1)) dirty [2] 
(
	.clk,
	.read,
	.load(dirty_load),
	.index,
	.datain(dirty_in),
	.dataout(dirty_out)
);

array #(.s_index(s_index), .width(1)) valid [2] 
(
	.clk,
	.read,
	.load(valid_load),
	.index,
	.datain(1'b1),
	.dataout(valid_out)
);

array #(.s_index(s_index), .width(s_tag)) tag_arr [2] 
(
	.clk,
	.read,
	.load(tag_load),
	.index,
	.datain(tag),
	.dataout(tag_out)
);


data_array #(.s_offset(s_offset), .s_index(s_index)) line [2] 
(
	.clk,
	.read(data_read),
	.write_en,
	.index,
	.datain(data_in),
	.dataout(data_out)
);

array #(.s_index(s_index), .width(1)) lru 
(
	.clk,
	.read,
	.load(lru_load),
	.index,
	.datain(lru_in),
	.dataout(lru_out)
);



always_comb
begin
	hit = (valid_out[0] && (tag == tag_out[0])) || (valid_out[1] && (tag == tag_out[1]));
	lru_load = hit;
	lru_in = (valid_out[0] && (tag == tag_out[0]));
	pmem_read = ((hit == 0) && mem_read && (dirty_out[lru_out] == 0)) || ((hit == 0) && mem_write && (dirty_out[lru_out] == 0));
	pmem_write = (hit == 0) && mem_read && (dirty_out[lru_out]);
	pmem_wdata = data_out[lru_in];
	mem_rdata256 = data_out[~lru_in];
	pmem_addr = {32{1'bz}};
	if(pmem_read) 
		pmem_addr = {{mem_addr[31:5]},{5'b0}};
	if(pmem_write)
		pmem_addr = {{tag_out[lru_out]},{index},{5'b0}};

	tag_load[0] = 0;
	tag_load[1] = 0;
	valid_load[0] = 0;
	valid_load[1] = 0;
	tag_load[lru_out] = (pmem_resp && pmem_read);
	valid_load[lru_out] = tag_load[lru_out];
	dirty_load[0] = 0;
	dirty_load[1] = 0;
	if(hit)
	begin
		dirty_load[~lru_in] = mem_write;
		dirty_in = mem_write;
		dirty_load[lru_in] = 0;
	end
	else
	begin
		dirty_load[lru_out] = pmem_resp && pmem_write;
		dirty_load[~lru_out] = 0;
		dirty_in = 0;
	end
	// dirty_load = (pmem_resp && pmem_write) || (hit && mem_write);
	// dirty_in = (hit && mem_write);
	mem_resp = (pmem_read == 0) && (pmem_write == 0);
	// not sure, probably
	data_read[0] = 0;
	data_read[1] = 0;
	data_read[~lru_in] = hit;
	data_read[lru_in] = pmem_write;
	write_en[0] = 0;
	write_en[1] = 0;
	data_in[0] = {s_line{1'bx}};
	data_in[1] = {s_line{1'bx}};
	if(tag_load[lru_out])
	begin
		write_en[lru_out] = {s_mask{1'b1}};
		data_in[lru_out] = pmem_rdata;// from pmem
	end
	if(dirty_in)
	begin
		write_en[~lru_in] = mem_byte_enable256;//from bus adapter
		data_in[~lru_in] = mem_wdata256;// from bus adapter
	end
end


endmodule :cache
