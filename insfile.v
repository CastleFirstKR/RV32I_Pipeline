`timescale 1ns / 1ps


module InstructionMemoryFile(Address,Data,Clk,Rst);
	input 		[31:0]	Address;
	input 	    	  	Clk,Rst;
	output      [31:0] 	Data;

	reg        	[7:0] 	imembank [0:128];  //  8x64  64B memory

initial begin 
	$readmemh("Imem.txt",imembank);  
end 

assign Data = {imembank[Address+3'b11],imembank[Address+2'b10], imembank[Address+2'b01],imembank[Address]} ;

endmodule



