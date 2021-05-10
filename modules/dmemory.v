module dmemory(
	input clock,
	input read_write,
	input [31:0] address,
	input [31:0] data_in,
	input [1:0] access_size,
	output reg [31:0] data_out
);

`define PC_INIT 32'h01000000

reg [31:0] xfile [0:`MEM_DEPTH-1];
reg [7:0] mem [0:`MEM_DEPTH-1];
wire [31:0] addr;
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

assign addr = (address >= `PC_INIT) ? (address - `PC_INIT) : address;

always @(read_write, addr, access_size) begin // read
	if (access_size == 2'b00) begin
		data_out[7:0] = mem[(addr + 0)]; // 1 byte
		data_out[31:8] = 24'h000000;
	end else if (access_size == 2'b01) begin	// 2 bytes
		data_out[7:0] = mem[(addr + 0)];
		data_out[15:8] = mem[(addr + 1)];
		data_out[31:16] = 16'h0000;
	end else if (access_size == 2'b10) begin // 4 bytes
		data_out[7:0] = mem[(addr + 0)];
		data_out[15:8] = mem[(addr + 1)];
		data_out[23:16] = mem[(addr + 2)];
		data_out[31:24] = mem[(addr + 3)];
	end else begin
		data_out = 32'h00000000;
	end
end

always @(posedge clock) begin // write
	if (read_write) begin
		mem[addr + 0] <= data_in[7:0]; // 1 byte
		if (access_size > 2'b00) begin // 2 byte
			mem[addr+ 1] <= data_in[15:8];
			if (access_size > 2'b01) begin // 4 byte
				mem[addr + 2] <= data_in[23:16];
				mem[addr + 3] <= data_in[31:24];
			end
		end
	end
end

endmodule
