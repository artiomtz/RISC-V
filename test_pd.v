module top;
wire clock, reset;
	clockgen clkg(
	.clk(clock),
	.rst(reset)
);
design_wrapper dut(
	.clock(clock),
	.reset(reset)
);

`define PC_INIT 32'h01000000
`define ECALL 7'h73

integer reg_index = 0;
integer line = 0;
integer last_line = 0;
reg stack_use = 0;

initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0,dut.core.imem);
	$dumpvars(0,dut.core.decoder);
	$dumpvars(0,dut.core.rgstr_file);
	$dumpvars(0,dut.core.al_u);
	$dumpvars(0,dut.core.dmem);
	$dumpvars(0,dut.core.write_back);
	$display("\n[PD4] REGISTER FILE ON START:\n");
	
	for (reg_index=0; reg_index<32; reg_index=reg_index+1) begin
		$display("[%2d] %x", reg_index, dut.core.rgstr_file.reg_file[reg_index]);
	end
	$display("\n[PD4] RUNNING TEST:\n");
end 

always @(posedge clock) begin
	if(!reset) begin
		if (line >= 100000) begin // running too long
			$display("\n[PD4] GAVE UP AFTER 100K LINES\n");
			$finish;
		end
		
		if ((last_line > 0) && (line >= last_line + 3)) begin // finish
			if (stack_use) begin
				$display("[PD4] DONE EXECUTING - EXITED WITH STACK POINTER\n");				
			end else begin
				$display("[PD4] DONE EXECUTING - EXITED WITH ECALL\n");				
			end
			$display("[PD4] REGISTER FILE:\n");
			for (reg_index = 0; reg_index < 32; reg_index = reg_index + 1) begin
				$display("[%2d] %x", reg_index, dut.core.rgstr_file.reg_file[reg_index]);
			end
			$display("\n[PD4] DONE\n");
			$finish;
		end
		
		line = line + 1;
		$display("[PD4] LINE %1d", line);
		// $display("[PD4] STACK POINTER: %x", dut.core.rgstr_file.reg_file[2]);
		
		if ((!stack_use) && (dut.core.rgstr_file.reg_file[2] < `PC_INIT + `MEM_DEPTH)) begin // sp usage
			stack_use = 1;
		end else if ((stack_use) && (last_line == 0) && (dut.core.rgstr_file.reg_file[2] == `PC_INIT + `MEM_DEPTH)) begin // sp reseted
			last_line = line - 3;
		end
		
		if ((dut.core.dec_opcode == `ECALL) && (last_line == 0)) begin // ecall
			last_line = line;
		end
		
		$display("[F] %x %x",
		dut.core.pc,
		dut.core.imem_out);
		$display("[D] %x %x %x %x %x %x %x %x %x",
		dut.core.pc,
		dut.core.decoder.reg_dec_opcode,
		dut.core.decoder.reg_dec_rd,
		dut.core.decoder.reg_dec_rs1,
		dut.core.decoder.reg_dec_rs2,
		dut.core.decoder.reg_dec_funct3,
		dut.core.decoder.reg_dec_funct7,
		dut.core.decoder.reg_dec_imm,
		dut.core.decoder.reg_dec_shamt);
		$display("[R] %x %x %x %x %x %x",
		dut.core.dec_rs1,
		dut.core.dec_rs2,
		dut.core.dec_rd,
		dut.core.reg_rs1,
		dut.core.reg_rs2,
		dut.core.reg_wen);
		$display("[E] %x %x %x %x",
		dut.core.pc,
		dut.core.alu_rd,
		dut.core.alu_rd,
		dut.core.pc_sel);
		$display("[M] %x %x %x %x %x",
		dut.core.pc,
		dut.core.pipe_alu_m,
		dut.core.dmem_wr,
		dut.core.dec_mem_access,
		dut.core.dmem_data_in);
		$display("[W] %x %x %x %x\n",
		dut.core.pc,
		dut.core.reg_wen,
		dut.core.dec_rd,
		dut.core.pipe_wb_w);
	end
end

endmodule
