module hazard(input  BranchD, 
			  input  MemtoRegE, RegWriteE,
			  input  MemtoRegM, RegWriteM,
			  input  RegWriteW,
			  output StallF, StallD, FlushE,
			  output ForwardAD, ForwardBD,
			  output [1:0] ForwardAE, ForwardBE,
			  input [4:0] RsD, RtD, RsE, RtE,
              input [4:0] WriteRegE,
			  input [4:0] WriteRegM,
			  input [4:0] WriteRegW,
			  input		  jump);
			  
  wire lwstall, branchstall;
  reg [1:0] AE, BE;
  
  assign ForwardAD = (RsD!=0) & (RsD==WriteRegM) & RegWriteM;
  assign ForwardBD = (RtD!=0) & (RtD==WriteRegM) & RegWriteM;
  assign lwstall = ((RsD==RtE) | (RtD==RtE)) & MemtoRegE;
  assign branchstall = BranchD & (RegWriteE & ((WriteRegE==RsD)|(WriteRegE==RtD))
								| (MemtoRegM & ((WriteRegM==RsD)|(WriteRegM==RtD))));
  assign StallF = lwstall | branchstall;
  assign StallD = lwstall | branchstall | jump;
  assign FlushE = lwstall | branchstall | jump;
  
  always @(*)
  begin
	if((RsE!=0) & (RsE==WriteRegM) & RegWriteM)
		AE = 2'b10;
	else if((RsE!=0) & (RsE==WriteRegW) & RegWriteW)
		AE = 2'b01;
	else
		AE = 2'b00;
  end
  always @(*)
  begin
	if((RtE!=0) & (RtE==WriteRegM) & RegWriteM)
		BE = 2'b10;
	else if((RtE!=0) & (RtE==WriteRegW) & RegWriteW)
		BE = 2'b01;
	else
		BE = 2'b00;
  end
  
  assign ForwardAE = AE;
  assign ForwardBE = BE;
endmodule