module o_cache #(
	parameter s_offset = 5,
   parameter s_index  = 3,
   parameter s_tag    = 32 - s_offset - s_index,
   parameter s_mask   = 2**s_offset,
   parameter s_line   = 8*s_mask,
   parameter num_sets = 2**s_index
)
(
	input logic clk,
	input [31:0] mem_addr,
	
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

logic [31:0] mem_address, mem_byte_enable256, pmem_address;
logic dirty_load [2];
logic valid_load [2];
logic data_read, pmem_load;
logic dirty_out [2];
logic [31:0] write_en [2];
logic [s_line-1:0] data_in [2];
logic [s_line-1:0] data_out [2];
logic hit_way [2];
logic valid_out [2];
logic [s_tag-1:0] tag_out [2];
logic [s_tag-1:0] tag;
logic [s_index-1:0] index;
logic read, hit, lru_out, datamux_sel, dirty_in, pmem_r, pmem_w;
logic [1:0] writemux_sel [2];
logic [s_line-1:0] mem_wdata256, mem_rdata256;

assign tag = mem_addr[31:(s_index + s_offset)];
assign index = mem_addr[(s_index + s_offset-1):s_offset];
assign read = mem_read | mem_write;
assign hit_way[0] = (valid_out[0] && (tag == tag_out[0]));
assign hit_way[1] = (valid_out[1] && (tag == tag_out[1]));
assign hit = hit_way[0] | hit_way[1];

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
	.load(valid_load),
	.index,
	.datain(tag),
	.dataout(tag_out)
);

array #(.s_index(s_index), .width(1)) lru 
(
	.clk,
	.read,
	.load(hit),
	.index,
	.datain(hit_way[0]),
	.dataout(lru_out)
);

register mem_reg
(
	.clk,
	.load(1'b1),
	.reset(1'b0),
	.in(mem_addr),
	.out(mem_address)
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

mux4 line_write_mux [2]
(
	.sel(writemux_sel),
	.a({32{1'b0}}),
	.b(mem_byte_enable256),
	.c({32{1'b1}}),
	.d(),
	.f(write_en)
);

mux4 #(.width(s_line)) line_in_mux [2]
(
	.sel(writemux_sel),
	.a({s_line{1'bz}}),
	.b(mem_wdata256),
	.c(pmem_rdata),
	.d(),
	.f(data_in)
);

mux2 #(.width(s_line)) data_out_mux
(
	.sel(datamux_sel),
	.a(data_out[0]),
	.b(data_out[1]),
	.f(mem_rdata256)
);

assign pmem_load = read;

register #(.width(s_line)) pmem_wdata_reg
(
	.clk,
	.load(pmem_load),
	.reset(pmem_resp),
	.in(mem_rdata256),
	.out(pmem_wdata)
);

register pmem_address_reg
(
	.clk,
	.load(pmem_load),
	.reset(pmem_resp),
	.in(pmem_address),
	.out(pmem_addr)
);

register #(.width(1)) pmem_read_reg
(
	.clk,
	.load(pmem_load),
	.reset(pmem_resp),
	.in(pmem_r),
	.out(pmem_read)
);

register #(.width(1)) pmem_write_reg
(
	.clk,
	.load(pmem_load),
	.reset(pmem_resp),
	.in(pmem_w),
	.out(pmem_write)
);

//assign pmem_wdata = mem_rdata256;

bus_adapter adapter 
(
	.mem_wdata256,
	.mem_rdata256,
	.mem_wdata,
	.mem_rdata,
	.mem_byte_enable,
	.mem_byte_enable256,
	.address(mem_addr)
);

enum int unsigned {
	check_tag,
	allocate,
	write_back
} state, next_state;

always_comb
begin : next_state_logic
	next_state = state;
	case(state)
		check_tag:
		begin
			next_state = check_tag;
			if((hit == 0) && (mem_write | mem_read))
			begin
				// if dirty, then write_back, if  clean, then write_back
				if(dirty_out[lru_out])
					next_state = write_back;
				else
					next_state = allocate;
			end
		end
		allocate:
		begin
			if(pmem_resp)
				next_state = check_tag;
		end
		write_back:
		begin
			if(pmem_resp)
				next_state = allocate;
		end
	endcase
end

always_comb
begin : state_actions
	mem_resp = 0;
	data_read = 0;
	pmem_address = {32{1'bz}};
	pmem_r = 0;
	pmem_w = 0;
	writemux_sel[0] = 0;
	writemux_sel[1] = 0;
	datamux_sel = 1'bx;
	dirty_in = 0;
	dirty_load[0] = 0;
	dirty_load[1] = 0;
	valid_load[0] = 0;
	valid_load[1] = 0;
	case(state)
		check_tag:
		begin
			mem_resp = hit && read;
			if(read)
			begin
				data_read = 1;
			end
			if(hit)
			begin
				datamux_sel = hit_way[1];
				if(mem_write)
				begin
					writemux_sel[hit_way[1]] = 1;
					dirty_in = 1;
					dirty_load[hit_way[1]] = 1;
				end
			end
		end
		allocate:
		begin
			pmem_r = 1;
			pmem_address = {{mem_addr[31:5]},{5'b0}};
			if(pmem_resp)
			begin
				writemux_sel[lru_out] = 2;
				dirty_load[lru_out] = 1;
				valid_load[lru_out] = 1;
			end
		end
		write_back:
		begin
			pmem_w = 1;
			datamux_sel = lru_out;
			pmem_address = {{tag_out[lru_out]},{mem_addr[s_index + 4:5]},{5'b0}};
		end
	endcase
end

initial begin
	state = check_tag;
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end


endmodule : o_cache