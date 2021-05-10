module imemory(
	input clock,
	input read_write,
	input [31:0] address,
	input [31:0] data_in,
	output [31:0] data_out
);

`define PC_INIT 32'h01000000

reg [31:0] xfile [0:`MEM_DEPTH-1];
reg [7:0] mem [0:`MEM_DEPTH-1];
integer i;

initial begin
	$readmemh(`MEM_PATH, xfile);
	for (i=0 ; i<`MEM_DEPTH-1 ; i=i+1) begin
		mem[i*4+0] = xfile[i][7:0];
		mem[i*4+1] = xfile[i][15:8];
		mem[i*4+2] = xfile[i][23:16];
		mem[i*4+3] = xfile[i][31:24];
	end
end

assign data_out[7:0] = (address >= `PC_INIT) ? mem[(address - `PC_INIT + 0)] : 8'h00;
assign data_out[15:8] = (address >= `PC_INIT) ? mem[(address - `PC_INIT + 1)] : 8'h00;
assign data_out[23:16] = (address >= `PC_INIT) ? mem[(address - `PC_INIT + 2)] : 8'h00;
assign data_out[31:24] = (address >= `PC_INIT) ? mem[(address - `PC_INIT + 3)] : 8'h00;

always @(posedge clock ) begin
	if ((read_write) && (address - `PC_INIT < `MEM_DEPTH - 3)) begin
		mem[address - `PC_INIT+ 0] <= data_in[7:0];
		mem[address - `PC_INIT + 1] <= data_in[15:8];
		mem[address - `PC_INIT + 2] <= data_in[23:16];
		mem[address - `PC_INIT + 3] <= data_in[31:24];
	end
end

endmodule
