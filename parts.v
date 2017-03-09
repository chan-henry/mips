module regfile(input         clk, 
               input         we3, 
               input  [4:0]  ra1, ra2, wa3, 
               input  [31:0] wd3, 
               output [31:0] rd1, rd2);

  reg [31:0] rf[31:0];

  // three ported register file
  // read two ports combinationally
  // write third port on falling edge of clock
  // register 0 hardwired to 0

  always @(negedge clk)
    if (we3) rf[wa3] <= wd3;	

  assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
  assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule

module adder(input [31:0] a, b,
             output [31:0] y);

  assign y = a + b;
endmodule

module sl2(input  [31:0] a,
           output [31:0] y);

  // shift left by 2
  assign y = {a[29:0], 2'b00};
endmodule

module signext(input  [15:0] a,
               output [31:0] y);
              
  assign y = {{16{a[15]}}, a};
endmodule

module zeroext(input  [15:0] a,
               output [31:0] y);
              
  assign y = {16'b0000000000000000, a};
endmodule

module flopr #(parameter WIDTH = 8)
              (input                  clk, reset,
               input      [WIDTH-1:0] d, 
               output reg [WIDTH-1:0] q);

  always @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule

module flopenr #(parameter WIDTH = 8)
                (input                  clk, reset,
                 input                  en,
                 input      [WIDTH-1:0] d, 
                 output reg [WIDTH-1:0] q);
 
  always @(posedge clk)
    if      (reset) q <= 0;
    else if (en)    q <= d;
endmodule

module flopfetch #(parameter WIDTH = 32)
                (input                  clk, reset,
                 input                  en,
                 input      [WIDTH-1:0] pcnext, 	//PC'
                 output reg [WIDTH-1:0] PCF);	//PCF
 
  always @(posedge clk, posedge reset)
    if      (reset) PCF <= 0;
    else if (~en)   PCF <= pcnext;
	else			PCF <= PCF;
endmodule

module flopdecode #(parameter WIDTH = 32)
                (input                  clk, reset,
                 input                  en, clr,
                 input      [WIDTH-1:0] InstrF, PCPlus4F,	//instrF, PCPlus4F
                 output reg [WIDTH-1:0] InstrD, PCPlus4D);	//instrD, PCPlus4D
 
  always @(posedge clk, posedge reset)
    if      (reset | clr)
	begin
		InstrD <= 0;
		PCPlus4D <= 0;
	end
    else if (~en)
	begin
		InstrD <= InstrF;
		PCPlus4D <= PCPlus4F;
	end
	else
	begin
		InstrD <= InstrD;
		PCPlus4D <= PCPlus4D;
	end
endmodule

module flopexecute #(parameter WIDTH = 32)
              (input                  clk, reset, clr,
			   input			[4:0] RsD, RtD, RdD,	//5-bit registers
			   input				  RegWriteD,		//Control signals
			   input				  MemtoRegD,
			   input				  MemWriteD,
			   input			[2:0] ALUControlD,
			   input				  ALUSrcD,
			   input				  RegDstD,
               input      [WIDTH-1:0] AD, BD, SignImmD,		//32-bit operands
			   output reg		[4:0] RsE,RtE,RdE,	//5-bit registers
			   output reg			  RegWriteE,		//Control signals
			   output reg			  MemtoRegE,
			   output reg			  MemWriteE,
			   output reg		[2:0] ALUControlE,
			   output reg			  ALUSrcE,
			   output reg			  RegDstE,
               output reg [WIDTH-1:0] AE, BE, SignImmE);		//32-bit operands

  always @(posedge clk, posedge reset)
    if (reset | clr) begin
		RsE <= 0;
		RtE <= 0;
		RdE <= 0;
		RegWriteE <= 0;
		MemtoRegE <= 0;
		MemWriteE <= 0;
		ALUControlE <= 0;
		ALUSrcE <= 0;
		RegDstE <= 0;
		AE <= 0;
		BE <= 0;
		SignImmE <= 0;
	end
    else begin
		RsE <= RsD;
		RtE <= RtD;
		RdE <= RdD;
		RegWriteE <= RegWriteD;
		MemtoRegE <= MemtoRegD;
		MemWriteE <= MemWriteD;
		ALUControlE <= ALUControlD;
		ALUSrcE <= ALUSrcD;
		RegDstE <= RegDstD;
		AE <= AD;
		BE <= BD;
		SignImmE <= SignImmD;
	end
endmodule

module flopmemory #(parameter WIDTH = 32)
              (input                  clk, reset,
			   input				  RegWriteE,	//Control signals
			   input				  MemtoRegE,
			   input				  MemWriteE,
               input      [WIDTH-1:0] ALUOutE, WriteDataE,		//ALUOutE, WriteDataE
			   input			[4:0] WriteRegE,	//WriteRegE
			   output reg			  RegWriteM,
			   output reg			  MemtoRegM,
			   output reg			  MemWriteM,
               output reg [WIDTH-1:0] ALUOutM, WriteDataM,		//ALUOutM, WriteDataM
			   output reg		[4:0] WriteRegM);

  always @(posedge clk, posedge reset)
    if (reset) begin
		RegWriteM <= 0;
		MemtoRegM <= 0;
		MemWriteM <= 0;
		ALUOutM <= 0;
		WriteDataM <= 0;
		WriteRegM <= 0;
	end
    else begin
		RegWriteM <= RegWriteE;
		MemtoRegM <= MemtoRegE;
		MemWriteM <= MemWriteE;
		ALUOutM <= ALUOutE;
		WriteDataM <= WriteDataE;
		WriteRegM <= WriteRegE;
	end
endmodule

module flopwriteback #(parameter WIDTH = 8)
              (input                  clk, reset,
			   input				  RegWriteM,	//Control signals
			   input				  MemtoRegM,
               input      [WIDTH-1:0] ReadDataM, ALUOutM,		//ReadDataM, ALUOutM
			   input			[4:0] WriteRegM,
			   output reg			  RegWriteW, MemtoRegW,
               output reg [WIDTH-1:0] ReadDataW, ALUOutW,		//ReadDataW, ALUOutW
			   output reg		[4:0] WriteRegW);

  always @(posedge clk, posedge reset)
    if (reset) begin
		ReadDataW <= 0;
		ALUOutW <= 0;
		WriteRegW <= 0;
		RegWriteW <= 0;
		MemtoRegW <= 0;
	end
    else begin
		ReadDataW <= ReadDataM;
		ALUOutW <= ALUOutM;
		WriteRegW <= WriteRegM;
		RegWriteW <= RegWriteM;
		MemtoRegW <= MemtoRegM;
	end
endmodule

module mux2 #(parameter WIDTH = 8)
             (input  [WIDTH-1:0] d0, d1, 
              input              s, 
              output [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 
endmodule

module mux3 #(parameter WIDTH = 32)
             (input  [WIDTH-1:0] d0, d1, d2,
              input        [1:0] s,
              output reg [WIDTH-1:0] y);
	always @(*)
		case(s)
			2'b00: y <= d0;
			2'b01: y <= d1;
			2'b10: y <= d2;
			default: y <= 2'bxx;
		endcase
	
endmodule