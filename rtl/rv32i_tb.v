`timescale 1ns / 1ps

module TB();

reg Rst,Clk;

	RV32I RVCPU(Clk,Rst);

initial begin
	Rst=1'b0;
	Clk =1'b0;
	#5 Rst=1'b1;

	forever	#5 Clk = !Clk;
	end

initial
	begin


	#500 $finish;
	end
endmodule
