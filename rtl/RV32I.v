`timescale 1ns / 1ps


module RV32I(Clk,Rst);

	input Clk,Rst;
	// clock , reset setting

	wire PCSrc; // branch or not 
	wire [31:0] PCin,PC,PC_4; // PCin -> branch or not, PC-> current inst address , PC_4 -> PC+4;
	wire [31:0] AddressIn,Instruction; // ADDRESS IN -> rael value
	reg  [31:0] PCreg; // 

	wire ALUsrc,MemRead,MemWrite,MemtoReg,RegWrite,AddSel,Link,Branch1,Branch0,Lui;
	wire regWen_WB;
	wire [1:0] ALUOp;
	wire [2:0] funct3_ID;
	wire [4:0] Rs1_ID,Rs2_ID,rd_WB, Rd;
	wire [6:0] Opcode;
	wire [11:0] ControlWire1;
	wire [31:0] data1,data2,writeData_WB,Instruction_ID,Immediate_ID;

	wire Zero,Lui_Ex,ALUsrc_Ex,RegWrite_EX,Branch1_Ex;
	wire [1:0] AluOp_Ex;
	wire [2:0] funct3;
	wire [3:0] ALUCnt;
	wire [4:0] Rd_EX;
	wire [6:0] funct7;
	wire [8:0] ControlWire2;
	wire [31:0] ALUresult,A,B,A0,B0,A1,B1;
	wire [31:0] Imm32,BrAdd,PC_EX,data1_Ex,data2_Ex;

	wire zero_MEM,AddSel_MEM,Link_MEM,Branch_MEM_1,Branch_MEM_0,memWrite_MEM,memRead_MEM,RegWrite_MEM;
	wire [ 1:0] ControlWire3;
 	wire [ 4:0] Rd_MEM;
	wire [31:0] OffsetAddress,BranchOffset,ALUAddress,ReadData,WriteData_MEM,writeBack_MEM,PCLink;
	
	wire RegWrite_WB,MemtoReg_WB;
	wire [31:0] readData_WB,writeBack_WB;

	wire memRead_EX;
	
	wire [ 4:0] Rs1_ID_EX,Rs2_ID_EX,Rd_EX_MEM,Rd_MEM_WB;

	reg stallIF,stallID,NOP;
	reg [1:0] InA,InB;
	reg flushIF,flushID,flushEX;
	reg [ 95:0] IF_ID_pipereg;
	reg [196:0] ID_EX_pipereg;
	reg [141:0] EX_MEM_pipereg;
	reg [ 70:0] MEM_WB_pipereg;



// StallIF -> instruction Fetch level Stalling
always@(posedge Clk or negedge Rst) begin
		if(~Rst)
			PCreg   <= 32'd0;
		else if(stallIF==1'b0)                 // Check for IF Stall
			PCreg	<= PCin ;				  // Update PC at posedge CLK1
		else
			PCreg	<= PCreg;				// for stall process, doens't update the  PC 
end


	
// IF 
// process: UPDATE PC VALUE -> Using instruction memory , update instruction, -> set next PC (PC+4 or Branch or Jal)
	
assign PC=PCreg; // PCreg has the current PC value
assign PCSrc = (((zero_MEM^Branch_MEM_0)||Link_MEM) && Branch_MEM_1) ; // PCSrc -> Branch , jump process. 

	Add 	PCAddressIncrement(PC_4,PC,32'd4);		             // Adder for PC increment PC_4=PC+4

	InstructionMemoryFile IMF (PC,Instruction,Clk,Rst); // Instruction Memory

	Mux2 	PCAddressSel(PCin,PC_4,OffsetAddress,PCSrc);      // Next Address Selection 32 bit wide 2X1 Mux


always@(posedge Clk or negedge Rst) begin 

		if(~Rst) begin
			IF_ID_pipereg <= 96'd0;
		end
		else begin
		  if(stallID==1'b0) begin 
			IF_ID_pipereg[31: 0] <= Instruction;	  // Forward Instruction to  ID
			IF_ID_pipereg[63:32] <= PC;				 // Forward PC address to ID
			IF_ID_pipereg[95:64] <= PC_4;			// Forward PC+4 address to ID 
		  end
		  else begin
		      if(flushIF==1'b1) begin
		          IF_ID_pipereg  <= 96'b0;
		      end
		      else begin
		          IF_ID_pipereg <= IF_ID_pipereg;
		      end
		 end  
	end
end	

assign Instruction_ID 	= IF_ID_pipereg[31:0]; 	   // Extract Instruction
assign Opcode 			= IF_ID_pipereg[6:0];     // Extract Opcode
assign funct3_ID 		= IF_ID_pipereg[14:12]; //Extract Funct3 -> for addi or subi, lw, sw  etc
assign Rs2_ID	  		= IF_ID_pipereg[24:20];  // Extract reg select bits for rs1 
assign Rs1_ID	  		= IF_ID_pipereg[19:15];	// Extract reg select bits for rs2
assign Rd 				= IF_ID_pipereg[11: 7];// Extract reg select bits for rd

// ControlWire for FlushID, , NOR -> for stalling ( NO OPERATION) -> Means no enter to process.


// for stall or flush process 
assign ControlWire1= (NOP || flushID) ? 12'b0XXXXX0XXXX:{Branch1,Lui,ALUOp,ALUsrc,
        AddSel,Link,Branch0,MemWrite,MemRead,RegWrite,MemtoReg};

	Control ControlDecoder(Opcode,funct3_ID,ALUsrc,MemtoReg,RegWrite,
	           MemRead,MemWrite,AddSel,Link,Branch1,Branch0,ALUOp,Lui);
	//  Decodes instructions in ID stage and forwards the control signals to other stages
	RegisterFile GPR(data1,data2,Rs1_ID,Rs2_ID,rd_WB,writeData_WB,Clk,Rst,RegWrite_WB);
	//  General Purpose Register File x0-x31, two read ports and a write port
	ImGen	ImmediateGen(Immediate_ID,Instruction_ID);
	//  Generates 32 bit Immediate value as per instruction
	
	
	
always @(posedge Clk or negedge Rst)  begin
 	if(~Rst)
 		ID_EX_pipereg <= 197'd0;
 	else begin
		ID_EX_pipereg[ 31: 0 ] <= IF_ID_pipereg[63:32]; 	  // Forward PC.
		ID_EX_pipereg[ 63:32 ] <= data1 ;	  			     //  Forward Rs1 Data
		ID_EX_pipereg[ 95:64 ] <= data2 ;				  	//   Forward Rs2 Data
		ID_EX_pipereg[127:96 ] <= Immediate_ID ;		   //    Forward Immediate Data
		ID_EX_pipereg[159:128] <= IF_ID_pipereg[95:64];	  //     Forward PC+4
		ID_EX_pipereg[164:160] <= Rd ;					 //      Forward Rd Select
		ID_EX_pipereg[176:165] <= ControlWire1 ; 	 	//       Forward Control Signals
		ID_EX_pipereg[186:177] <= {Instruction_ID[14:12],Instruction_ID[31:25]} ;// {func3,func7}
		ID_EX_pipereg[196:187] <= {Rs1_ID,Rs2_ID};    // Store for Forwarding
 	end
end

assign Imm32=ID_EX_pipereg[127:96];
assign PC_EX=ID_EX_pipereg[ 31: 0];

assign data1_Ex = ID_EX_pipereg[ 63:32 ];
assign data2_Ex = ID_EX_pipereg[ 95:64 ];

assign ALUsrc_Ex 	=ID_EX_pipereg[172];
assign AluOp_Ex	 	=ID_EX_pipereg[174:173];
assign Lui_Ex	 	=ID_EX_pipereg[175];
assign Branch1_Ex    =ID_EX_pipereg[176];
assign RegWrite_EX 	=ID_EX_pipereg[166];
assign Rd_EX    	=ID_EX_pipereg[164:160];

assign funct3=ID_EX_pipereg[186:184];
assign funct7=ID_EX_pipereg[183:177];

assign ControlWire2= (flushEX) ? 9'b00xx0xxxx:
        {Branch1_Ex,Zero,ID_EX_pipereg[171:165]};
	// flush EX deasserts control introducing Bubbles/No operations

    // PC_EX -> current PC value,  imme -> 1bit가 생략되어있다. 2byte instruction 지원을 고려하여서
	Add AddressAdder(BrAdd,PC_EX,{Imm32[30:0],1'b0}); 
	// Adder for Computing Branch Addresses (Imm32 bits are left shifted)
	// lnA -> data1_Ex -> register rs1 value,  ALUAddress ->  ALUResult, writeData_WB -> WB level data(data forwarding process)
	Mux4 BusA1(A1,data1_Ex,ALUAddress,writeData_WB,32'd0,InA); // Forward Reg A mux   ,, EX <-> MEM,  EX <-> WB  Level
	Mux4 BusB1(B1,data2_Ex,ALUAddress,writeData_WB,32'd0,InB);// Forward Reg B mux

	Mux2 BusA0(A,A1,32'd0,Lui_Ex); 		 // Mux : Loads Rs1 Data to 0 for Lui instrucion
	Mux2 BusB0(B,B1,Imm32,ALUsrc_Ex);   // Mux : Selects between Immediate or Rs2 Data

	ALU  ALUUnit(Zero,ALUresult,A,B,ALUCnt);			 // ALU Unit takes in 4 bit Control from ALUCtrl
	ALUControl ALUCtrl(ALUCnt,AluOp_Ex,funct3,funct7);	// 2nd Level Control Decoder



always@(posedge Clk or negedge Rst) begin
	if(~Rst)
		EX_MEM_pipereg <=142'd0;
	else begin
		EX_MEM_pipereg [ 31: 0 ] <= ALUresult;					  // ALU Result
		EX_MEM_pipereg [ 63: 32] <= BrAdd;						 // PC+Offset ,Branch Address
		EX_MEM_pipereg [ 95: 64] <= B1;							// Rs2 data to write to Memory
		EX_MEM_pipereg [127: 96] <= ID_EX_pipereg[159:128];	   // PC+4
		EX_MEM_pipereg [132:128] <= Rd_EX;					  // RD.EX
		EX_MEM_pipereg [141:133] <= ControlWire2;			 // Control Signals for further stages
	end
end


assign ControlWire3 = EX_MEM_pipereg[134:133];

assign BranchOffset	= EX_MEM_pipereg [63:32];	 // Branch address = PC+ Shifted Immediate
assign ALUAddress  	= EX_MEM_pipereg [31: 0];	// ALU address    = Reg + Immediate , ALU result value 
assign WriteData_MEM= EX_MEM_pipereg [95:64];  // RS2 Data for writing to memory ,RS1 -> based address in SW instruction
assign PCLink =EX_MEM_pipereg [127: 96]; // PC+4 value 
assign Rd_MEM =EX_MEM_pipereg [132:128];   // RD_REG NUMBER OF CURRENT Instruction
 
assign Branch_MEM_1 = EX_MEM_pipereg[141]; // Branch or not 
assign zero_MEM  	= EX_MEM_pipereg[140];	// Used for Branches
assign AddSel_MEM  	= EX_MEM_pipereg[139];  // change PC value using pc or reg
assign Link_MEM		= EX_MEM_pipereg[138];   // Set for Unconditional Jumps
assign Branch_MEM_0	= EX_MEM_pipereg[137];	//  Set for Branches
assign memWrite_MEM = EX_MEM_pipereg[136];
assign memRead_MEM  = EX_MEM_pipereg[135];
assign RegWrite_MEM = EX_MEM_pipereg[134];


	Mux2 AddressSel(OffsetAddress,BranchOffset,ALUAddress,AddSel_MEM); // Selects between PC Offset/Reg Offset
	Mux2 LinkSel(writeBack_MEM,ALUAddress,PCLink,Link_MEM); 		  // Selects between writing back PC+4/ALUOut
	DataMemoryFile DMF(ReadData,ALUAddress,WriteData_MEM,memWrite_MEM,memRead_MEM,Clk,Rst);

always @(posedge Clk or negedge Rst) begin
	if(~Rst) 
	MEM_WB_pipereg <= 70'd0;
	else begin
	 	MEM_WB_pipereg[31:0 ] <= ReadData; // Data read from Memory
	 	MEM_WB_pipereg[63:32] <= writeBack_MEM; // Data from ALU / Link Reg
	 	MEM_WB_pipereg[68:64] <= Rd_MEM; // Write Data Select Register
	 	MEM_WB_pipereg[70:69] <= ControlWire3; // Control Signals
	end
end


assign RegWrite_WB  = MEM_WB_pipereg[70];
assign MemtoReg_WB  = MEM_WB_pipereg[69];    // MemtoReg -> using memory for writing Register
assign readData_WB  = MEM_WB_pipereg[31: 0]; // from meemory data by processing LW
assign writeBack_WB = MEM_WB_pipereg[63:32];  // From ALU result 
assign rd_WB 		= MEM_WB_pipereg[68:64]; // number of destination Register

 	Mux2 WriteBackSel(writeData_WB,readData_WB,writeBack_WB,MemtoReg_WB); 

// structual hazard -> XXXXXXXXXXXXXX
// data hazard -> Using stalling and Forwarding
// control hazard -> Using flush  

// memRead_EX -> 클럭에 따라 1 에서 X로 변하게 될 것이다.
// Controlwire가  XXXXXX로 변하기 때문이다. 
assign memRead_EX= ID_EX_pipereg[167]; // MemRead 


// MEMrEAD_Ex -> clk 에 따라 변화하게 된다. 
always@(*) begin			// Stall due to Load 
	//,Rs2 , Rs1_ID 는 변화하지 않는다 .(STALL 하는 중에) => instruction Fetch 된 게 같기때문에 
	// stall signal -> 1 clk 발생한다. 
	// stall 이후에는 LW (MEM) and ADD (ID) 인 상태이므로 data forwarding 작업을 진행하여 
	// stall 기능을 최소화 해준다.
	
	if(memRead_EX && ((Rd_EX == Rs1_ID) || (Rd_EX == Rs2_ID))) 
			begin // Load data is used for next INSTRUCTION  -> Stalling until load data to RD 
			// stalling by load -> stall Instruction Fetch, Instruction Decode 
			
				stallIF=1'b1;
				stallID=1'b1;
				NOP=1'b1;
			end
		else begin
				stallIF=1'b0;
				stallID=1'b0;
				NOP=1'b0;
			end
end

always@(*) begin			// Branch & Jump Flush

		if(PCSrc)	// Next address is Jump/Branch
			begin
				flushIF=1'b1;
				flushID=1'b1;
				flushEX=1'b1;
			end
		else begin
				flushIF=1'b0;
				flushID=1'b0;
				flushEX=1'b0;
			end
end

/*----------------------------------------------------------------------------------------------------------
												FORWARDING UNIT
	-----------------------------------------------------------------------------------------------------------*/

assign Rs1_ID_EX = ID_EX_pipereg  [196:192];
assign Rs2_ID_EX = ID_EX_pipereg  [191:187];
assign Rd_EX_MEM = EX_MEM_pipereg [132:128];
assign Rd_MEM_WB = MEM_WB_pipereg [ 68:64];


always@(*) begin			// Register Forwarding Unit 
	
	   // register process  ADD ,SUB
		if(RegWrite_MEM  && Rd_EX_MEM !=5'd0 && Rd_EX_MEM == Rs1_ID_EX) // ID -- EX  Dependency Rs1
			InA=2'b01;
			
	   // In load instruction, stall 1clk and data forwarding.

		else if(RegWrite_WB   && Rd_MEM_WB !=5'd0 && Rd_MEM_WB == Rs1_ID_EX) // ID -- MEM Dependency Rs1
			InA=2'b10;
		else 
			InA=2'b00;

		if(RegWrite_MEM  && Rd_EX_MEM !=5'd0 && Rd_EX_MEM == Rs2_ID_EX) // ID -- EX  Dependency Rs2
			InB=2'b01;
			
	   // In load instruction, stall 1clk and data forwarding.

		else if(RegWrite_WB   && Rd_MEM_WB !=5'd0 && Rd_MEM_WB == Rs2_ID_EX) // ID -- MEM Dependency Rs2
			InB=2'b10;
		else 
			InB=2'b00;
end	


endmodule

