module reg_file(
	input clock,
	input reset,
	input write_enable,
	input [4:0] addr_rs1,
	input [4:0] addr_rs2,
	input [4:0] addr_rd,
	input [31:0] data_rd,
	output [31:0] data_rs1,
	output [31:0] data_rs2	
);

`define PC_INIT 32'h01000000

/* verilator lint_off UNOPTFLAT */
reg [31:0] reg_file [31:0];
integer i;

initial begin
	for (i=0; i<32; i=i+1) begin
		reg_file[i] = 32'h00000000;
	end
	reg_file[2] = `MEM_DEPTH + `PC_INIT;
end

assign data_rs1 = reg_file[addr_rs1];
assign data_rs2 = reg_file[addr_rs2];

always @(posedge clock) begin
	if (reset) begin
		for (i=0 ; i<32 ; i=i+1) begin
			reg_file[i] = 32'h00000000;
		end
		reg_file[2] = `MEM_DEPTH + `PC_INIT;
	end else if (write_enable) begin
		reg_file[addr_rd] <= data_rd;
		reg_file[0] <= 0;
	end
end

endmodule
