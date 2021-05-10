module decode(
	input clock,
	input [31:0] dec_in,
	input [31:0] reg_file_rs1,
	input [31:0] reg_file_rs2,
	output reg [6:0] dec_opcode,
	output reg [4:0] dec_rd,
	output reg [4:0] dec_rs1,
	output reg [4:0] dec_rs2,
	output reg [2:0] dec_funct3,
	output reg [6:0] dec_funct7,
	output reg [31:0] dec_imm,
	output reg [4:0] dec_shamt,
	output reg pc_sel,
	output reg regfile_wen,
	output reg [1:0] a_sel,
	output reg [1:0] b_sel,
	output reg [3:0] alu_sel,
	output reg [1:0] wb_sel,
	output reg mem_rw,
	output reg mem_data_sel,
	output reg [1:0] mem_access_size,
	output reg load_signed,
	output reg stall
);

reg [4:0] reg_dec_rd;
reg [4:0] reg_rd_x;
reg [4:0] reg_rd_m;
reg [4:0] reg_dec_rs1;
reg [4:0] reg_dec_rs2;
reg reg_regfile_wen;
reg reg_wen_x;
reg reg_wen_m;
reg [1:0] reg_wb_sel;
reg [1:0] reg_wb_sel_x;
reg reg_mem_rw;
reg reg_mem_rw_x;
reg [1:0] reg_mem_access_size;
reg [1:0] reg_mem_access_size_x;
reg reg_load_signed;
reg reg_load_signed_x;
reg [31:0] reg_dec_imm;
reg [4:0] reg_dec_shamt;
reg reg_pc_sel;
reg [1:0] reg_a_sel;
reg [1:0] reg_b_sel;
reg [3:0] reg_alu_sel;
reg [6:0] reg_dec_opcode;
reg [2:0] reg_dec_funct3;
reg [6:0] reg_dec_funct7;
reg reg_mem_data_sel;
reg two_cycle_flush = 0;

`define RTYPE 7'b0110011
`define ITYPE 7'b0010011
`define STYPE 7'b0100011
`define BTYPE 7'b1100011
`define JAL 7'b1101111
`define LUI 7'b0110111
`define AUIPC 7'b0010111
`define JALR 7'b1100111
`define LTYPE 7'b0000011
`define ECALL 7'b1110011

/* verilator lint_off UNOPTFLAT */
initial begin
	stall = 0;
	two_cycle_flush = 0;
	dec_opcode = 7'h0;	
	dec_rs1 = 5'h0;
	dec_rs2 = 5'h0;
	dec_rd = 5'h0;
	dec_funct3 = 3'h0;
	dec_funct7 = 7'h0;
	dec_imm = 32'h0;
	dec_shamt = 5'h0;
	pc_sel = 0;
	regfile_wen = 0;
	a_sel = 2'b00;
	b_sel = 2'b00;
	alu_sel = 4'h0;
	wb_sel = 2'b11;
	mem_rw = 0;
	mem_data_sel = 0;
	mem_access_size = 2'b11;
	load_signed = 0;
end

always @(posedge clock) begin
	if ((pc_sel) || (two_cycle_flush)) begin // jump flush
		if ((dec_opcode == `BTYPE) || (dec_opcode == `JAL) || (dec_opcode == `JALR)) begin // second flush 
			two_cycle_flush <= 1;
		end else begin
			two_cycle_flush <= 0;
		end
		dec_opcode <= 7'h0;	
		reg_rd_x <= 5'h0;
		dec_funct3 <= 3'h0;
		dec_funct7 <= 7'h0;
		dec_imm <= 32'h0;
		dec_shamt <= 5'h0;
		pc_sel <= 0;
		reg_wen_x <= 0;
		a_sel <= 2'b00;
		b_sel <= 2'b00;
		alu_sel <= 4'h0;
		reg_wb_sel_x <= 2'b11;
		reg_mem_rw_x <= 0;
		reg_mem_data_sel <= 0;
		reg_mem_access_size_x <= 2'b11;
		reg_load_signed_x <= 0;
	
	end else begin // no stall nor branch
		two_cycle_flush <= 0;
		reg_rd_x <= reg_dec_rd;
		reg_wen_x <= reg_regfile_wen;
		reg_wb_sel_x <= reg_wb_sel;
		reg_mem_rw_x <= reg_mem_rw;
		reg_mem_access_size_x <= reg_mem_access_size;
		reg_load_signed_x <= reg_load_signed;
		
		dec_imm <= reg_dec_imm;	
		dec_shamt <= reg_dec_shamt;	
		pc_sel <= reg_pc_sel;
		alu_sel <= reg_alu_sel;
		dec_opcode <= reg_dec_opcode;
		dec_funct3 <= reg_dec_funct3;
		dec_funct7 <= reg_dec_funct7;
		
		if ((reg_dec_rs1 == reg_rd_x) && (reg_rd_x != 5'h0))begin // M-X bypassing
			a_sel <= 2'b10;
		end else if ((reg_dec_rs1 == reg_rd_m) && (reg_rd_m != 5'h0)) begin // W-X bypassing
			a_sel <= 2'b11;
		end else begin
			a_sel <= reg_a_sel;
		end
		
		if ((reg_dec_rs2 == reg_rd_x) && (dec_in[6:0] != `STYPE) // M-X bypassing
		&& (reg_rd_x != 5'h0)) begin
			b_sel <= 2'b10;
		end else if ((reg_dec_rs2 == reg_rd_m) && (dec_in[6:0] != `STYPE) // W-X bypassing
		&& (reg_rd_m != 5'h0))begin
			b_sel <= 2'b11;
		end else begin
			b_sel <= reg_b_sel;
		end
		
		if ((reg_dec_rs2 == reg_rd_x) && (dec_in[6:0] == `STYPE)) begin // W-M bypassing
			reg_mem_data_sel <= 1;
		end else begin
			reg_mem_data_sel <= 0;
		end
		
	end	
	reg_rd_m <= reg_rd_x;
	dec_rd <= reg_rd_m;

	reg_wen_m <= reg_wen_x;
	regfile_wen <= reg_wen_m;
	
	wb_sel <= reg_wb_sel_x;	
	mem_rw <= reg_mem_rw_x;	
	mem_access_size <= reg_mem_access_size_x;	
	mem_data_sel <= reg_mem_data_sel;
	load_signed <= reg_load_signed_x;
end

always @(*) begin
	if (dec_in[6:0] == `RTYPE) begin
		reg_dec_opcode = dec_in[6:0];
		reg_dec_rd = dec_in[11:7];
		reg_dec_rs1 = dec_in[19:15];
		reg_dec_rs2 = dec_in[24:20];
		reg_dec_funct3 = dec_in[14:12];
		reg_dec_funct7 = dec_in[31:25];
		reg_dec_imm = 0;
		reg_dec_shamt = 0;
		reg_pc_sel = 0;
		reg_regfile_wen = 1;
		reg_a_sel = 2'b00;
		reg_b_sel = 2'b00;
		reg_mem_access_size = 2'b11;
		reg_wb_sel = 2'b01;
		reg_mem_rw = 0;
		reg_load_signed = 0;
		if ((dec_in[14:12] == 3'b000) && (dec_in[31:25] == 7'b0000000)) begin // add
			reg_alu_sel = 4'b0000;
		end else if (dec_in[14:12] == 3'b000) begin // sub
			reg_alu_sel = 4'b0001;
		end else if (dec_in[14:12] == 3'b001) begin // sll
			reg_alu_sel = 4'b0010;
		end else if (dec_in[14:12] == 3'b010) begin // slt
			reg_alu_sel = 4'b0011;
		end else if (dec_in[14:12] == 3'b011) begin // sltu
			reg_alu_sel = 4'b0100;
		end else if (dec_in[14:12] == 3'b100) begin // xor
			reg_alu_sel = 4'b0101;
		end else if ((dec_in[14:12] == 3'b101) && (dec_in[31:25] == 7'b0000000)) begin // srl
			reg_alu_sel = 4'b0110;
		end else if (dec_in[14:12] == 3'b101) begin // sra
			reg_alu_sel = 4'b0111;
		end else if (dec_in[14:12] == 3'b110) begin // or
			reg_alu_sel = 4'b1000;
		end else if (dec_in[14:12] == 3'b111) begin // and
			reg_alu_sel = 4'b1001;
		end else begin
			reg_alu_sel = 4'b1111;
		end
		
	end else if (dec_in[6:0] == `ITYPE) begin
		reg_dec_opcode = dec_in[6:0];
		reg_dec_rd = dec_in[11:7];
		reg_dec_rs1 = dec_in[19:15];
		reg_dec_rs2 = 0;
		reg_dec_funct3 = dec_in[14:12];
		reg_dec_funct7 = 0;
		reg_dec_imm = {{20{dec_in[31]}}, dec_in[31:20]}; // immediate generation
		reg_pc_sel = 0;
		reg_regfile_wen = 1;
		reg_a_sel = 2'b00;
		reg_b_sel = 2'b01;
		reg_wb_sel = 2'b01;
		reg_mem_rw = 0;
		reg_mem_access_size = 2'b11;
		reg_load_signed = 0;
		if ((dec_in[14:12] == 3'b001) || (dec_in[14:12] == 3'b101) ) begin // shamt
			reg_dec_shamt = dec_in[24:20];
		end else begin // imm
			reg_dec_shamt = 0;
		end
		if (dec_in[14:12] == 3'b000) begin // addi
			reg_alu_sel = 4'b0000;
		end else if (dec_in[14:12] == 3'b010) begin // slti
			reg_alu_sel = 4'b0011;
		end else if (dec_in[14:12] == 3'b011) begin // sltiu
			reg_alu_sel = 4'b0100;
		end else if (dec_in[14:12] == 3'b100) begin // xori
			reg_alu_sel = 4'b0101;
		end else if (dec_in[14:12] == 3'b110) begin // ori
			reg_alu_sel = 4'b1000;
		end else if (dec_in[14:12] == 3'b111) begin // andi
			reg_alu_sel = 4'b1001;
		end else if (dec_in[14:12] == 3'b001) begin // slli
			reg_alu_sel = 4'b0010;
		end else if ((dec_in[14:12] == 3'b101) && (dec_in[31:25] == 7'b0000000)) begin // srli
			reg_alu_sel = 4'b0110;
		end else if (dec_in[14:12] == 3'b101) begin // srai
			reg_alu_sel = 4'b0111;
		end else begin
			reg_alu_sel = 4'b1111;
		end
		
	end else if (dec_in[6:0] == `STYPE) begin
		reg_dec_opcode = dec_in[6:0];
		reg_dec_rd = 0;
		reg_dec_rs1 = dec_in[19:15];
		reg_dec_rs2 = dec_in[24:20];
		reg_dec_funct3 = dec_in[14:12];
		reg_dec_funct7 = 0;
		reg_dec_imm = {{20{dec_in[31]}}, {dec_in[31:25], dec_in[11:7]}}; // immediate generation
		reg_dec_shamt = 0;
		reg_pc_sel = 0;
		reg_regfile_wen = 0;
		reg_a_sel = 2'b00;
		reg_b_sel = 2'b01;
		reg_alu_sel = 0;
		reg_wb_sel = 2'b11;
		reg_mem_rw = 1;
		reg_mem_access_size = 2'b10;
		reg_load_signed = 0;
		
	end else if (dec_in[6:0] == `BTYPE) begin // with branch comparator
	
		reg_dec_opcode = dec_in[6:0];
		reg_dec_rd = 0;
		reg_dec_rs1 = dec_in[19:15];
		reg_dec_rs2 = dec_in[24:20];
		reg_dec_funct3 = dec_in[14:12];
		reg_dec_funct7 = 0;
		reg_dec_imm = {{19{dec_in[31]}}, {dec_in[31], dec_in[7], dec_in[30:25], dec_in[11:8]}, 1'h0}; // immediate generation
		reg_dec_shamt = 0;
		reg_regfile_wen = 0;
		reg_a_sel = 2'b01;
		reg_b_sel = 2'b01;
		reg_alu_sel = 0;
		reg_wb_sel = 2'b11;
		reg_mem_rw = 0;
		reg_mem_access_size = 2'b11;
		reg_load_signed = 0;
		
		if (dec_in[14:12] == 3'b000) begin // beq
			reg_pc_sel = (reg_file_rs1 == reg_file_rs2);
		end else if (dec_in[14:12] == 3'b001) begin // bne
			reg_pc_sel = (reg_file_rs1 != reg_file_rs2);
		end else if (dec_in[14:12] == 3'b100) begin // blt
			reg_pc_sel = ($signed(reg_file_rs1) < $signed(reg_file_rs2));
		end else if (dec_in[14:12] == 3'b101) begin // bge
			reg_pc_sel = ($signed(reg_file_rs1) > $signed(reg_file_rs2));
		end else if (dec_in[14:12] == 3'b110) begin // bltu
			reg_pc_sel = ($unsigned(reg_file_rs1) < $unsigned(reg_file_rs2));
		end else if (dec_in[14:12] == 3'b111) begin // bgeu
			reg_pc_sel = ($unsigned(reg_file_rs1) > $unsigned(reg_file_rs2));
		end
			
	end else if (dec_in[6:0] == `JAL) begin
		reg_dec_opcode = dec_in[6:0];	
		reg_dec_rd = dec_in[11:7];
		reg_dec_rs1 = 0;
		reg_dec_rs2 = 0;
		reg_dec_funct3 = 0;
		reg_dec_funct7 = 0;
		reg_dec_imm = {{12{dec_in[31]}}, {dec_in[31], dec_in[19:12], dec_in[20], dec_in[30:21]} << 1}; // immediate generation
		reg_dec_shamt = 0;
		reg_pc_sel = 1;
		reg_regfile_wen = 1;
		reg_a_sel = 2'b01;
		reg_b_sel = 2'b01;
		reg_alu_sel = 0;
		reg_wb_sel = 2'b10;
		reg_mem_rw = 0;
		reg_mem_access_size = 2'b11;
		reg_load_signed = 0;
		
	end else if ((dec_in[6:0] == `LUI) || (dec_in[6:0] == `AUIPC) ) begin // U type
		reg_dec_opcode = dec_in[6:0];	
		reg_dec_rd = dec_in[11:7];
		reg_dec_rs1 = 0;
		reg_dec_rs2 = 0;
		reg_dec_funct3 = 0;
		reg_dec_funct7 = 0;
		reg_dec_imm = {dec_in[31:12], {12'b0}}; // immediate generation
		reg_dec_shamt = 0;
		reg_pc_sel = 0;
		reg_regfile_wen = 1;
		reg_b_sel = 2'b01;
		reg_alu_sel = 0;
		reg_wb_sel = 2'b01;
		reg_mem_rw = 0;
		reg_mem_access_size = 2'b11;
		reg_load_signed = 0;
		if (dec_in[6:0] == `LUI) begin
			reg_a_sel = 2'b00;
		end else if (dec_in[6:0] == `AUIPC) begin
			reg_a_sel = 2'b01;
		end
		
	end else if ((dec_in[6:0] == `JALR) || (dec_in[6:0] == `LTYPE) || (dec_in[6:0] == `ECALL)) begin
		reg_dec_opcode = dec_in[6:0];
		reg_dec_rd = dec_in[11:7];
		reg_dec_rs1 = dec_in[19:15];
		reg_dec_rs2 = 0;
		reg_dec_funct3 = dec_in[14:12];
		reg_dec_funct7 = 0;
		reg_dec_imm = {{20{dec_in[31]}}, dec_in[31:20]}; // immediate generation
		reg_dec_shamt = 0;
		reg_a_sel = 2'b00;
		reg_alu_sel = 0;
		reg_mem_rw = 0;
		if (dec_in[6:0] == `JALR) begin
			reg_pc_sel = 1;
			reg_regfile_wen = 1;
			reg_b_sel = 2'b01;
			reg_wb_sel = 2'b10;
			reg_mem_access_size = 2'b11;
			reg_load_signed = 0;
		end else if (dec_in[6:0] == `LTYPE) begin
			reg_pc_sel = 0;
			reg_regfile_wen = 1;
			reg_b_sel = 2'b01;
			reg_wb_sel = 2'b00;
			if (dec_in[14:12] < 3'b100) begin // signed
				reg_load_signed = 1;
			end else begin // unsigned
				reg_load_signed = 0;
			end
			if ((dec_in[14:12] == 3'b000) || (dec_in[14:12] == 3'b100)) begin // 1 byte
				reg_mem_access_size = 2'b00;
			end else if ((dec_in[14:12] == 3'b001) || (dec_in[14:12] == 3'b101)) begin // half word
				reg_mem_access_size = 2'b01;
			end else begin // word
				reg_mem_access_size = 2'b10;
			end
		end else if (dec_in[6:0] == `ECALL) begin
			reg_pc_sel = 0;
			reg_regfile_wen = 0;
			reg_b_sel = 2'b01;
			reg_wb_sel = 2'b11;
			reg_mem_access_size = 2'b11;
			reg_load_signed = 0;
		end
		
	end else begin // flush
		reg_dec_opcode = 7'h0;	
		reg_dec_rd = 5'h0;
		reg_dec_rs1 = 5'h0;
		reg_dec_rs2 = 5'h0;
		reg_dec_funct3 = 3'h0;
		reg_dec_funct7 = 7'h0;
		reg_dec_imm = 32'h0;
		reg_dec_shamt = 5'h0;
		reg_pc_sel = 0;
		reg_regfile_wen = 0;
		reg_a_sel = 2'b00;
		reg_b_sel = 2'b00;
		reg_alu_sel = 4'h0;
		reg_wb_sel = 2'b11;
		reg_mem_rw = 0;
		reg_mem_access_size = 2'b11;
		reg_load_signed = 0;
	end
	
	if (((dec_opcode == `LTYPE) && ((reg_dec_rs1 == reg_rd_x) // LD use stall
	|| ((reg_dec_rs2 == reg_rd_x) && (dec_in[6:0] != `STYPE))))
	||	((((reg_dec_rs1 == dec_rd) || (reg_dec_rs2 == dec_rd)) // W-D hazard stall
	&& (dec_rd != 5'h0)) && !pc_sel)
	|| ((reg_dec_rs2 == reg_rd_m) && (dec_in[6:0] == `STYPE) && (reg_rd_m != 5'h0))) begin // SW stall
		stall = 1;
		reg_dec_opcode = 7'h0;	
		reg_dec_rd = 5'h0;
		reg_dec_rs1 = 5'h0;
		reg_dec_rs2 = 5'h0;
		reg_dec_funct3 = 3'h0;
		reg_dec_funct7 = 7'h0;
		reg_dec_imm = 32'h0;
		reg_dec_shamt = 5'h0;
		reg_pc_sel = 0;
		reg_regfile_wen = 0;
		reg_a_sel = 2'b00;
		reg_b_sel = 2'b00;
		reg_alu_sel = 4'h0;
		reg_wb_sel = 2'b11;
		reg_mem_rw = 0;
		reg_mem_access_size = 2'b11;
		reg_load_signed = 0;
	end else begin
		stall = 0;
	end
	dec_rs1 = stall ? 5'h0 : reg_dec_rs1;
	dec_rs2 = stall ? 5'h0 : reg_dec_rs2;
end

endmodule
