module hazardtest();
  
  reg         clk;
  reg         reset;
  
  reg		  jump;
  reg		  BranchD;
  reg  [4:0] RsD, RtD, RsE, RtE;
  reg  [4:0] WriteRegE;
  reg		  MemtoRegE, RegWriteE;
  reg  [4:0] WriteRegM;
  reg		  MemtoRegM, RegWriteM;
  reg  [4:0] WriteRegW;
  reg		  RegWriteW;
  
  reg		  StallFexpected, StallDexpected, FlushEexpected;
  reg  		  ForwardADexpected, ForwardBDexpected;
  reg  [1:0]  ForwardAEexpected, ForwardBEexpected;
  
  wire		  StallF, StallD, FlushE;
  wire  	  ForwardAD, ForwardBD;
  wire	[1:0]  ForwardAE, ForwardBE;
  
  reg  [31:0] vectornum, errors;
  reg  [51:0]  testvectors[10000:0];

  // instantiate device under test
  hazard dut( BranchD,
			  MemtoRegE, RegWriteE,
			  MemtoRegM, RegWriteM,
			  RegWriteW,
			  StallF, StallD, FlushE,
			  ForwardAD, ForwardBD,
			  ForwardAE, ForwardBE,
			  RsD, RtD, RsE, RtE,
			  WriteRegE, WriteRegM, WriteRegW, jump);

  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors
  // and pulse reset
  initial
    begin
      $readmemh("hazardtest.tv", testvectors);
      vectornum = 0; errors = 0;
      reset = 1; #27; reset = 0;
    end

  // apply test vectors on rising edge of clk
  always @(posedge clk)
    begin
      #1; { jump, BranchD, 
			MemtoRegE, RegWriteE,
			MemtoRegM, RegWriteM,
			RegWriteW,
			StallFexpected, StallDexpected, FlushEexpected,
			ForwardADexpected, ForwardBDexpected,
			ForwardAEexpected, ForwardBEexpected,
			RsD, RtD, RsE, RtE,
			WriteRegE, WriteRegM, WriteRegW} = testvectors[vectornum];
    end

  // check results on falling edge of clk
  always @(negedge clk)
    if (~reset) begin // skip cycles during reset
      if ({StallF, StallD, FlushE,
			ForwardAD, ForwardBD,
			ForwardAE, ForwardBE}
			!==
			{StallFexpected, StallDexpected, FlushEexpected,
			 ForwardADexpected, ForwardBDexpected,
			 ForwardAEexpected, ForwardBEexpected}) begin  // check result
        $display("Error: inputs = %b", 
	         {jump, BranchD, RsD, RtD, RsE, RtE,
			  WriteRegE, MemtoRegE, RegWriteE,
			  WriteRegM, MemtoRegM, RegWriteM,
			  WriteRegW, RegWriteW});
		$display("  outputs = %b (%b expected)",
	         {StallF, StallD, FlushE,
			  ForwardAD, ForwardBD,
			  ForwardAE, ForwardBE},
			 {StallFexpected, StallDexpected, FlushEexpected,
			  ForwardADexpected, ForwardBDexpected,
			  ForwardAEexpected, ForwardBEexpected});
	errors = errors + 1;
      end
      vectornum = vectornum + 1;
      if (testvectors[vectornum] === 52'bx) begin 
        $display("%d tests completed with %d errors", 
	         vectornum, errors);
		$display("  outputs = %b (%b expected)",
	         {StallF, StallD, FlushE,
			  ForwardAD, ForwardBD,
			  ForwardAE, ForwardBE},
			 {StallFexpected, StallDexpected, FlushEexpected,
			  ForwardADexpected, ForwardBDexpected,
			  ForwardAEexpected, ForwardBEexpected});
        $stop;
      end
    end
endmodule