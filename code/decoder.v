`timescale 1ns / 1ps



module Control(Opcode,funct3,ALUsrc,MemtoReg,RegWrite,MemRead,MemWrite,AddSel,Link,Branch1,Branch0,ALUOp,Lui);

output [1:0] ALUOp;
input  [6:0] Opcode;
input  [2:0] funct3;

output 	reg ALUsrc,RegWrite,MemWrite,MemtoReg,MemRead,AddSel,Link,Lui;
output wire  Branch1,Branch0;

reg ALUOp1,ALUOp0;
reg    [1:0] Branch;
initial begin Branch =2'b00; end

assign {Branch1,Branch0}=Branch;

assign ALUOp= {ALUOp1,ALUOp0};


// ALUsrc -> Using  Immediate or NOT 
// MemtoReg -> Using memory data for write register or not
// RegWrite -> Update Register or not
// MemRead -> Using memory , read data or not
// MemWrite -> Using memory, write data to register or not
// AddSel ->  Using for  jump process(branch address) based Reg or not 
// Link -> jal, jr etc jump process
// Lui -> instruction for lui, lui instruction can make reg have 32bit immediate value.
// Branch -> is it branch process or not
// ALUop1 -> 


// Control signal setting
always@(Opcode) begin
		case(Opcode)
			7'b0110011: 	// R  type  
				begin
					ALUsrc 		= 1'b0; 
					MemtoReg	= 1'b1;
					RegWrite	= 1'b1;
					MemRead		= 1'b0;
					MemWrite	= 1'b0;
					AddSel		= 1'bX;
					Link		= 1'b0;
					Lui  		= 1'b0;
					Branch		= 2'b00;
					ALUOp1		= 1'b1;
					ALUOp0		= 1'b0;
				end
				
			7'b0000011: 	// I type Load
				begin
					ALUsrc 		= 1'b1;
					MemtoReg	= 1'b0;
					RegWrite	= 1'b1;
					MemRead		= 1'b1;
					MemWrite	= 1'b0;
					AddSel		= 1'bX;
					Link		= 1'b0;
					Lui  		= 1'b0;
					Branch		= 2'b00;
					ALUOp1		= 1'b0;
					ALUOp0		= 1'b0;
				end
				
			7'b0010011: 	// I type Arithmetic
				begin
					ALUsrc 		= 1'b1;
					MemtoReg	= 1'b1;
					RegWrite	= 1'b1;
					MemRead		= 1'b0;
					MemWrite	= 1'b0;
					AddSel		= 1'bX;
					Link		= 1'b0;
					Lui  		= 1'b0;
					Branch		= 2'b00;
					ALUOp1		= 1'b1;
					ALUOp0		= 1'b1;
				end
				
			7'b1100111: 	// UJ type Jalr
				begin
					ALUsrc 		= 1'b1;
					MemtoReg	= 1'b1;
					RegWrite	= 1'b1;
					MemRead		= 1'b0;
					MemWrite	= 1'b0;
					AddSel		= 1'b1;
					Link		= 1'b1;
					Lui  		= 1'b0;
					Branch		= 2'b10;
					ALUOp1		= 1'b0;
					ALUOp0		= 1'b1;
				end
				
			7'b0100011: 	// S  type  
				begin
					ALUsrc 		= 1'b1;
					MemtoReg	= 1'bX;
					RegWrite	= 1'b0;
					MemRead		= 1'b0;
					MemWrite	= 1'b1;
					AddSel		= 1'bX;
					Link		= 1'b0;
					Lui  		= 1'b0;
					Branch		= 2'b00;
					ALUOp1		= 1'b0;
					ALUOp0		= 1'b0;
				end

			7'b1100011: 	// SB type 
				begin
					ALUsrc 		= 1'b0;
					MemtoReg	= 1'bX;
					RegWrite	= 1'bX;
					MemRead		= 1'b0;
					MemWrite	= 1'b0;
					AddSel		= 1'b0;
					Link		= 1'b0;
					Lui  		= 1'b0;
					Branch		= {1'b1,funct3[2]^funct3[0]}; // bge -> 11 
					ALUOp1		= 1'b0;
					ALUOp0		= 1'b1;
				end
				
			7'b0110111: 	//  U type (Lui)
				begin
					ALUsrc 		= 1'b1;
					MemtoReg	= 1'b1;
					RegWrite	= 1'b1;
					MemRead		= 1'b0;
					MemWrite	= 1'b0;
					AddSel		= 1'bX;
					Link		= 1'b0;
					Lui  		= 1'b1;
					Branch		= 2'b00;
					ALUOp1		= 1'b0;  //config ALU to Add
					ALUOp0		= 1'b0;
				end
				
			7'b1101111: 	//  UJ type (Jal)
				begin
					ALUsrc 		= 1'b1;
					MemtoReg	= 1'b1;
					RegWrite	= 1'b1;
					MemRead		= 1'b0;
					MemWrite	= 1'b0;
					AddSel		= 1'b1;
					Link		= 1'b1;
					Lui  		= 1'b0;
					Branch		= 2'b10;
					ALUOp1		= 1'b0;
					ALUOp0		= 1'b1;
				end
			default:
					begin
						ALUsrc 		= 1'b0;
						MemtoReg	= 1'b0;
						RegWrite	= 1'b0;
						MemRead		= 1'b0;
						MemWrite	= 1'b0;
						AddSel		= 1'b1;
						Link		= 1'b0;
						Lui  		= 1'b0;
						Branch		= 2'b00;
						ALUOp1		= 1'bZ;
						ALUOp0		= 1'bZ;
					end
		endcase		
	end			
endmodule

// ALU Controller

module ALUControl(ALUCnt,AluOp,funct3,funct7);		// Takes in Instructions Funct field of 6 bits along with 2 bits of Alu Op decoded by Main Control
output reg 	[3:0] ALUCnt;
input  		[2:0] funct3;
input		[6:0] funct7;
input  		[1:0] AluOp;

/// AluOp -> divide by type of instruction

always@(AluOp,funct3,funct7)    begin
// funct7 -> [31:25]
// funct7 -> [14:12]

		case(AluOp)
			2'b00 : // LW or SW 
				ALUCnt = 4'b0010;
			
			2'b01 : 
				begin	
					case(funct3)
						3'b000: ALUCnt=4'b0110;	//Beq
						3'b001: ALUCnt=4'b0110;	//Bne
						3'b100: ALUCnt=4'b0111;	//Blt
						3'b101: ALUCnt=4'b0111;	//Bge
						default: ALUCnt=4'b0010; //Jalr
					endcase
				end
				
			2'b10 : // R-Type Function 3 and 7 defines ALU mode
				begin
					case(funct3)
						3'b000 : 
								case (funct7)
								7'b0000000:	ALUCnt = 4'b0010;	// ADD
								7'b0100000: ALUCnt = 4'b0110;	// SUB
									default : ALUCnt = 4'bZZZZ;
								endcase
						3'b001 : ALUCnt = 4'b1101;	// SLL
						3'b100 : ALUCnt = 4'b1100;	//XOR
						3'b101 : 
								case (funct7)
								7'b0000000:	ALUCnt = 4'b1110;// SRL
								7'b0100000: ALUCnt = 4'b1000;// SRA
									default : ALUCnt = 4'bZZZZ;
								endcase 
						3'b110 : ALUCnt = 4'b0001;	//OR
						3'b111 : ALUCnt = 4'b0000;	//AND

						default: 
							ALUCnt = 4'bZZZZ;
					endcase
				end
			2'b11:	// When Source 2 is Imm Data 
				begin 
					case(funct3)
						3'b000 : ALUCnt = 4'b0010;	// ADDI
						3'b001 : ALUCnt = 4'b1101;	// SLLI
						3'b100 : ALUCnt = 4'b1100;	//XORI
						3'b101 : 
								case (funct7)
								7'b0000000:	ALUCnt = 4'b1110;// SRLI
								7'b0100000: ALUCnt = 4'b1000;// SRAI
									default : ALUCnt = 4'bZZZZ;
								endcase 
						3'b110 : ALUCnt = 4'b0001;	//ORI
						3'b111 : ALUCnt = 4'b0000;	//ANDI

						default: 
							ALUCnt = 4'bZZZZ;
					endcase
				end
		endcase
	end
endmodule
