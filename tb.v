`timescale 1ns/1ps

module testbench();

  reg         clk;
  reg         reset;

  wire [31:0] aluout, writedata, readdata;
  wire memwrite;

  // instantiate device to be tested
  top dut(clk, reset, aluout, writedata, readdata, memwrite);
  
  // initialize test
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // check results
  always@(negedge clk)
    begin
      if(memwrite) begin
        if(aluout === 84 & writedata === 7) begin
          $display("Simulation succeeded");
	  $stop;
        end else if (aluout !== 80) begin
	  $display("Simulation failed");
          $stop;
	end
      end
    end
endmodule

