`timescale 1ns / 1ps

module DataMemoryFile(ReadData,Address,WriteData,memWrite,memRead,Clk,Rst);

	input 		[31:0] 	Address;
	input 		[31:0] 	WriteData;
	input 	    	 	Clk,memWrite,memRead,Rst;

	output      [31:0] 	ReadData;

	reg        [7:0] dataMem [0:63];  //8x64 Bits = 64 Byte memory

	initial begin $readmemh("Dmem.txt",dataMem);  end
	
	assign ReadData =(memRead)  ?   {dataMem[Address+2'b11],dataMem[Address+2'b10],dataMem[Address+2'b01],dataMem[Address]}:32'hZZZZZZZZ;
				// Scoops 4 8 bit memory locations at a time in Little Endian
	always @( * ) 
	begin
		if(memWrite) begin
		      {dataMem[Address+2'b11],dataMem[Address+2'b10],dataMem[Address+2'b01],dataMem[Address]} <= WriteData;
	    end
	end
endmodule

