module pd(
	input clock,
	input reset
);

`define PC_INIT 32'h01000000

/* verilator lint_off UNOPTFLAT */
reg [31:0] pc;
wire [31:0] imem_out;

wire [6:0] dec_opcode;
wire [4:0] dec_rd;
wire [4:0] dec_rs1;
wire [4:0] dec_rs2;
wire [2:0] dec_funct3;
wire [6:0] dec_funct7;
wire [31:0] dec_imm;
wire [4:0] dec_shamt;
wire [1:0] dec_mem_access;
wire dec_ld_sign;
wire stall;

wire pc_sel;
wire reg_wen;
wire [1:0] a_sel;
wire [1:0] b_sel;
wire [3:0] alu_sel;
wire [1:0] wb_sel;

wire [31:0] reg_rs1;
wire [31:0] reg_rs2;
wire [31:0] reg_rd;

wire [31:0] alu_rs1;
wire [31:0] alu_rs2;
wire [31:0] alu_rd;

wire [31:0] dmem_data_in;
wire dmem_data_sel;
wire dmem_wr;
wire [31:0] dmem_out;

reg [31:0] pipe_pc_d;
reg [31:0] pipe_pc_x;
reg [31:0] pipe_pc_m;
reg [31:0] pipe_rs1_x;
reg [31:0] pipe_rs2_x;
reg [31:0] pipe_rs2_m;
reg [31:0] pipe_alu_m;
reg [31:0] pipe_inst_d;
reg [31:0] pipe_wb_w;

imemory imem(
	.clock(clock),
	.read_write(1'b0),
	.address(pc),
	.data_in(0),
	.data_out(imem_out)
);

decode decoder(
	.clock(clock),
	.dec_in(pipe_inst_d),
	.reg_file_rs1(reg_rs1),
	.reg_file_rs2(reg_rs2),
	.dec_opcode(dec_opcode),
	.dec_rd(dec_rd),
	.dec_rs1(dec_rs1),
	.dec_rs2(dec_rs2),
	.dec_funct3(dec_funct3),
	.dec_funct7(dec_funct7),
	.dec_imm(dec_imm),
	.dec_shamt(dec_shamt),
	.pc_sel(pc_sel),
	.regfile_wen(reg_wen),
	.a_sel(a_sel),
	.b_sel(b_sel),
	.alu_sel(alu_sel),
	.wb_sel(wb_sel),
	.mem_rw(dmem_wr),
	.mem_data_sel(dmem_data_sel),
	.mem_access_size(dec_mem_access),
	.load_signed(dec_ld_sign),
	.stall(stall)
);

reg_file rgstr_file(
	.clock(clock),
	.reset(reset),
	.write_enable(reg_wen),
	.addr_rs1(dec_rs1),
	.addr_rs2(dec_rs2),
	.addr_rd(dec_rd),
	.data_rd(pipe_wb_w),
	.data_rs1(reg_rs1),
	.data_rs2(reg_rs2)
);

alu al_u(
	.pc(pipe_pc_x),
	.rs1(alu_rs1),
	.rs2(alu_rs2),
	.imm(dec_imm),
	.alu_sel(alu_sel),
	.a_sel(a_sel),
	.b_sel(b_sel),
	.next_rd(pipe_alu_m),
	.next_next_rd(pipe_wb_w),
	.rd(alu_rd)
);

dmemory dmem(
	.clock(clock),
	.read_write(dmem_wr),
	.address(pipe_alu_m),
	.data_in(dmem_data_in),
	.access_size(dec_mem_access),
	.data_out(dmem_out)
);

wb write_back(
	.wb_sel(wb_sel),
	.dmem_out(dmem_out),
	.alu_rd(pipe_alu_m),
	.pc(pipe_pc_m),
	.mem_ld_signed(dec_ld_sign),
	.mem_access_size(dec_mem_access),
	.reg_rd(reg_rd)
);

initial begin
	pc = `PC_INIT;
end

assign dmem_data_in = dmem_data_sel ? pipe_wb_w : pipe_rs2_m;
assign alu_rs1 = pipe_rs1_x;
assign alu_rs2 = ((alu_sel == 4'b0010) || (alu_sel == 4'b0110) || (alu_sel == 4'b0111)) ? {27'h0, dec_shamt} : pipe_rs2_x;

always @(posedge clock) begin
	if (reset) begin
		pc <= `PC_INIT;
	end else if (!stall) begin
		if (pc_sel) begin
			pc <= alu_rd;
		end else begin
			pc <= pc + 4;
		end
		pipe_pc_d <= pc;
		pipe_inst_d <= imem_out;
	end
	
	pipe_pc_x <= pipe_pc_d;
	pipe_pc_m <= pipe_pc_x;
	
	pipe_rs2_x <= reg_rs2;
	pipe_rs2_m <= pipe_rs2_x;
	
	pipe_rs1_x <= reg_rs1;
	pipe_alu_m <= alu_rd;
	pipe_wb_w <= reg_rd;
end

endmodule
