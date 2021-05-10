module alu(
	input [31:0] pc,
	input [31:0] rs1,
	input [31:0] rs2,
	input [31:0] imm,
	input [3:0] alu_sel,
	input [1:0] a_sel,
	input [1:0] b_sel,
	input [31:0] next_rd,
	input [31:0] next_next_rd,
	output reg [31:0] rd
);

wire [31:0] in_a, in_b;

initial begin
	rd = 0;
end

assign in_a = (a_sel == 2'b00) ? rs1 : (a_sel == 2'b01) ? pc : (a_sel == 2'b10) ? next_rd : next_next_rd;
assign in_b = (b_sel == 2'b00) ? rs2 : (b_sel == 2'b01) ? imm : (b_sel == 2'b10) ? next_rd : next_next_rd;

always @(*) begin
	if (alu_sel == 4'b0000) begin // add
		rd = in_a + in_b;
	end else  if (alu_sel == 4'b0001) begin // sub
		rd = in_a - in_b;
	end else  if (alu_sel == 4'b0010) begin // sll
		rd = in_a << in_b[4:0];
	end else  if (alu_sel == 4'b0011) begin // slt
		rd = $signed(in_a) < $signed(in_b) ? 1 : 0;
	end else  if (alu_sel == 4'b0100) begin // sltu
		rd = $unsigned(in_a) < $unsigned(in_b) ? 1 : 0;
	end else  if (alu_sel == 4'b0101) begin // xor
		rd = in_a ^ in_b;
	end else  if (alu_sel == 4'b0110) begin // srl
		rd = in_a >> in_b[4:0];
	end else  if (alu_sel == 4'b0111) begin // sra
		rd = $signed(in_a) >>> (in_b);
	end else  if (alu_sel == 4'b1000) begin // or
		rd = in_a | in_b;
	end else  if (alu_sel == 4'b1001) begin // and
		rd = in_a & in_b;
	end
end

endmodule
