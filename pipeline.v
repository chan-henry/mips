// Pipelined MIPS processor datapath
module mips(input         clk, reset,
            output [31:0] PCF,
            input  [31:0] InstrF,
            output        MemWriteM,
            output [31:0] ALUOutM, WriteDataM,
            input  [31:0] ReadDataM);

  wire        RegWriteD, MemtoRegD, MemWriteD,
              ALUSrcD, RegDstD, BranchD, jump;
  wire [31:0] InstrD;
  wire [2:0]  ALUControlD;

  controller c(InstrD[31:26], InstrD[5:0],
               MemtoRegD, MemWriteD, BranchD,
               ALUSrcD, RegDstD, RegWriteD, jump,
               ALUControlD);
  datapath dp(clk, reset, MemtoRegD, BranchD,
              ALUSrcD, RegDstD, RegWriteD, jump,
              ALUControlD,
              PCF, InstrF,
              ALUOutM, WriteDataM, ReadDataM, InstrD, MemWriteD,
			  MemWriteM);
endmodule

module controller(input  [5:0] op, funct,
                  output       MemtoRegD, MemWriteD,
                  output       BranchD, ALUSrcD,
                  output       RegDstD, RegWriteD,
                  output       jump,
                  output [2:0] ALUControlD);

  wire [1:0] aluop;

  maindec md(op, MemtoRegD, MemWriteD, BranchD,
             ALUSrcD, RegDstD, RegWriteD, jump,
             aluop);
  aludec  ad(funct, aluop, ALUControlD);
endmodule

module maindec(input  [5:0] op,
               output       MemtoRegD, MemWriteD,
               output       BranchD, ALUSrcD,
               output       RegDstD, RegWriteD,
               output       jump,
               output [1:0] aluop);

  reg [8:0] controls;

  assign {RegWriteD, RegDstD, ALUSrcD,
          BranchD, MemWriteD,
          MemtoRegD, jump, aluop} = controls;

  always @( * )
    case(op)
      6'b000000: controls <= 9'b110000010; //Rtyp
      6'b100011: controls <= 9'b101001000; //LW
      6'b101011: controls <= 9'b001010000; //SW
      6'b000100: controls <= 9'b000100001; //BEQ
      6'b001000: controls <= 9'b101000000; //ADDI
      6'b000010: controls <= 9'b000000100; //J
      default:   controls <= 9'bxxxxxxxxx; //???
    endcase
endmodule

module aludec(input      [5:0] funct,
              input      [1:0] aluop,
              output reg [2:0] alucontrol);

  always @( * )
    case(aluop)
      2'b00: alucontrol <= 3'b010;  // add
      2'b01: alucontrol <= 3'b110;  // sub
      default: case(funct)          // RTYPE
          6'b100000: alucontrol <= 3'b010; // ADD
          6'b100010: alucontrol <= 3'b110; // SUB
          6'b100100: alucontrol <= 3'b000; // AND
          6'b100101: alucontrol <= 3'b001; // OR
          6'b101010: alucontrol <= 3'b111; // SLT
          default:   alucontrol <= 3'bxxx; // ???
        endcase
    endcase
endmodule

module datapath(input         clk, reset,
                input         MemtoRegD, BranchD,
                input         ALUSrcD, RegDstD,
                input         RegWriteD, jump,
                input  [2:0]  ALUControlD,
                output [31:0] PCF,
                input  [31:0] InstrF,
                output [31:0] ALUOutM, WriteDataM,
                input  [31:0] ReadDataM,
				output [31:0] InstrD,
				input		  MemWriteD,
				output		  MemWriteM);
//Fetch Stage Wires
  wire [31:0] pcnext, pcnextbr, PCPlus4F;
//Decode Stage Wires
  wire [31:0] pcjump, RD1, RD2, AD, BD;
  wire [31:0] SignImmD, immextsh, PCPlus4D, PCBranchD;
  wire		  PCSrcD;
//Execute Stage Wires
  wire		  RegWriteE, MemtoRegE, MemWriteE;
  wire [2:0]  ALUControlE;
  wire		  ALUSrcE, RegDstE;
  wire [31:0] AE, BE, SrcAE, SrcBE, WriteDataE, SignImmE;
  wire [31:0] ALUOutE;
  wire [4:0]  RsE, RtE, RdE, WriteRegE;
//Memory Stage Wires
  wire		  RegWriteM, MemtoReg;
  wire [4:0]  WriteRegM;
//Writeback Stage Wires
  wire		  RegWriteW, MemtoRegW;
  wire [31:0] ReadDataW, ALUOutW, ResultW;
  wire [4:0]  WriteRegW;
//Hazard Unit Wires
  wire		  StallF, StallD, FlushE;
  wire		  ForwardAD, ForwardBD;
  wire [1:0]  ForwardAE, ForwardBE;

  // next PC logic
  assign PCSrcD = (BranchD & (AD===BD)) | jump;
  assign pcjump = {PCPlus4F[31:28], InstrD[25:0], 2'b00};
//  assign InstrDout = InstrD;

//  flopr #(32) pcreg(clk, reset, pcnext, pc);
  flopfetch #(32) fetch(clk, reset, StallF, pcnext, PCF);
  flopdecode #(32) decode(clk, reset, StallD, PCSrcD, InstrF, PCPlus4F, InstrD, PCPlus4D);
  flopexecute #(32) execute(clk, reset, FlushE, InstrD[25:21], InstrD[20:16], InstrD[15:11],
							RegWriteD, MemtoRegD, MemWriteD, ALUControlD, ALUSrcD, RegDstD,
							AD, BD, SignImmD, RsE, RtE, RdE, RegWriteE, MemtoRegE, MemWriteE,
							ALUControlE, ALUSrcE, RegDstE, AE, BE, SignImmE);
  flopmemory #(32) memory(clk, reset, RegWriteE, MemtoRegE, MemWriteE, ALUOutE, WriteDataE,
						  WriteRegE, RegWriteM, MemtoRegM, MemWriteM, ALUOutM, WriteDataM,
						  WriteRegM);
  flopwriteback #(32) writeback(clk, reset, RegWriteM, MemtoRegM, ReadDataM, ALUOutM, WriteRegM,
								RegWriteW, MemtoRegW, ReadDataW, ALUOutW, WriteRegW);
  adder       pcadd1(PCF, 32'b100, PCPlus4F);
  sl2         immsh(SignImmD, immextsh);
  adder       pcadd2(PCPlus4D, immextsh, PCBranchD);
  mux2 #(32)  pcbrmux(PCPlus4F, PCBranchD, PCSrcD,
                      pcnextbr);
  mux2 #(32)  pcmux(pcnextbr, pcjump, jump,
                    pcnext);

  // register file logic
  regfile     rf(clk, RegWriteW, InstrD[25:21],
                 InstrD[20:16], WriteRegW,
                 ResultW, RD1, RD2);
  mux2 #(5)   wrmux(RtE, RdE,
                    RegDstE, WriteRegE);
  mux2 #(32)  ADmux(RD1, ALUOutM, ForwardAD, AD);
  mux2 #(32)  BDmux(RD2, ALUOutM, ForwardBD, BD);
  mux2 #(32)  resmux(ALUOutW, ReadDataW,
                     MemtoRegW, ResultW);
  signext     se(InstrD[15:0], SignImmD);

  // ALU logic
  mux3 #(32)  srcAEmux(AE, ResultW, ALUOutM, ForwardAE, SrcAE);
  mux3 #(32)  srcBEmux(BE, ResultW, ALUOutM, ForwardBE, WriteDataE);
  mux2 #(32)  srcbmux(WriteDataE, SignImmE, ALUSrcE,
                      SrcBE);
  alu32       alu(SrcAE, SrcBE, ALUControlE,
                  ALUOutE);
  hazard	  hazardunit(BranchD, MemtoRegE, RegWriteE, MemtoRegM, RegWriteM,
						 RegWriteW, StallF, StallD, FlushE, ForwardAD, ForwardBD,
						 ForwardAE, ForwardBE, InstrD[25:21], InstrD[20:16], RsE, RtE,
						 WriteRegE, WriteRegM, WriteRegW, jump);
endmodule
