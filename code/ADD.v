`timescale 1ns / 1ps


// instruction memory => 4byte, , byte adrdress
module Add(Result, A, B);

	input 		[31:0] A,B;
	output  reg [31:0] Result;

always @(A,B)
begin
	Result=A+B;
end
endmodule
