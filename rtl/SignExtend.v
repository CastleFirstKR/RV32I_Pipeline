`timescale 1ns / 1ps

module ImGen(Out,Instruction);

    input  		[31:0] Instruction;
    
    output reg  [31:0] Out;
    
    wire [6:0] Opcode;
    wire [31:0] Ins;
    
    // Extracts and Extends the Immediate values from different types of Instruction
        always@(Instruction) begin
            begin
                case(Opcode)
                    7'b0000011,7'b0010011,7'b1100111 : Out = {{20{Ins[31]}},Ins[31:20]}; //signed extension 
                    // 12 Bit Imm at Ins[31:20] for I-type (Load,Arith,Jalr)
                    7'b0100011	: Out = {{20{Ins[31]}},Ins[31:25],Ins[11:7]}; //signed extension
                    // 12 Bit Imm at Ins[31:25],Ins[11:7] for S-Type
                    7'b1100011  : Out = {{20{Ins[31]}},Ins[31],Ins[7],Ins[30:25],Ins[11:8]}; // signed extension
                    // 12 Bit Imm for SB-type
                    7'b1101111  : Out = {{12{Ins[31]}},Ins[31],Ins[19:12],Ins[20],Ins[30:21]}; //signed extension,  chnage instruction address
                    //  20 Bit Imm for UJ-Type   
                    7'b0110111	: Out = {Ins[31:12],12'h000};
                    // 	20 Bit Imm for J-Type (LUI)
                    default: Out= 32'hZZZZ;
                endcase // Opcode
            end
        end
                    
    assign Opcode = Instruction[6:0];	// Extract Opcode
    assign Ins = Instruction;

endmodule
