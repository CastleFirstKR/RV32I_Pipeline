`timescale 1ns / 1ps


module RegisterFile(data1, data2, read1, read2, writeReg, writeData, Clk, Rst, regWen);
	input 		[31:0] writeData;
	input      	[ 4:0] read1, read2, writeReg;  // Register Number
	input 	    	  Clk, regWen, Rst; //regWen => Write Reg signal

	output      [31:0] data1, data2;

	reg       	 [31:0] registerbank [0:31];

    initial begin 
        $readmemh("Rmem.txt",registerbank);  //Register Reset
    end

	always @(posedge Clk) 
	begin
		if(~Rst) 
			begin
			 	$readmemh("Rmem.txt",registerbank);
			 end
	end

	always @( * ) 					// Writing at Negative Edge of clock
	begin
		registerbank[0] <= 32'd0;	// Regster 0번은 항상 0의값을 가진다. 
	
		if(regWen)
			registerbank[writeReg] <= writeData;
	end
	
	assign data1 = registerbank[read1];	// Port for Rs1
	assign data2 = registerbank[read2];	// Port for Rs2

endmodule



