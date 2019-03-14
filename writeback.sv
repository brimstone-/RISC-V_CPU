module writeback #(parameter width = 32)
(
	input rv32i_word 
);

mux8 regfilemux
(
	.sel(regfilemux_sel),
	.a(alu_out),
	.b({{31{1'b0}},br_en}),
	.c(u_imm),
	.d(mem_mask_out), // from rom
	.e(pc_plus4_out),
	.f(),
	.g(),
	.h(),
	.out(regfilemux_out)
);

endmodule : writeback
