`timescale 1ns/1ns

module tb_timetagger();

reg clk;

reg reset = 0;
reg activate = 0;
wire tx_out;

reg [3:0] detectors;

timetagger uut(
	detectors,
	clk,
	reset,
	activate,
	tx_out
);

// Clocks
initial clk = 0;
always #2 clk = ~clk;

// Simulate photons
initial detectors = 4'b0000;
//`define RANDOM_PEAKS
`ifdef RANDOM_PEAKS
initial begin
	if ((4'b1111 & $random) == 4'b0)
	begin
		detectors[0] = 1'b1;
		#10 detectors[0] = 1'b0;
	end
end
`else
always begin
	#20000 detectors[0] = 1'b1;
	#5  detectors[0] = 1'b0;
end
`endif

// These statements conduct the actual circuit test
initial begin
	$display($time, "     Starting...");

	$display($time, "  Starting detectors");
	reset = 1;
	// Reset before capturing events
	#100 reset = 0;
	#100 activate = 1;

	#100000 $stop;
end

endmodule

