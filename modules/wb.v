module wb(
	input [1:0] wb_sel,
	input [31:0] dmem_out,
	input [31:0] alu_rd,
	input [31:0] pc,
	input mem_ld_signed,
	input [1:0] mem_access_size,
	output [31:0] reg_rd	
);

reg [31:0] tmp_mem;

assign reg_rd = (wb_sel == 2'b00) ? tmp_mem : (wb_sel == 2'b01) ? alu_rd : (wb_sel == 2'b10) ? (pc + 4) : 32'h00000000;

always @(*) begin
	if (mem_ld_signed) begin // signed
		if (mem_access_size == 2'b00) begin // 1 bytes
			tmp_mem = {{24{dmem_out[7]}}, dmem_out[7:0]};
		end else if (mem_access_size == 2'b01) begin	// 2 bytes
			tmp_mem = {{16{dmem_out[15]}}, dmem_out[15:0]};
		end else begin // 4 bytes
			tmp_mem = dmem_out;			
		end
	end else begin // unsigned
		tmp_mem = dmem_out;	
	end
end

endmodule
