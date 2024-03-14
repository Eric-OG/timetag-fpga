`timescale 1ns/1ns

module tb_timetagger_100();

reg clk;

reg reset = 0;
reg activate = 0;
wire tx_out;

reg [99:0] detectors;

timetagger_100 uut(
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
initial detectors = 0;
always begin
	#20000 detectors[50] = 1'b1;
	#5  detectors[50] = 1'b0;
end

// These statements conduct the actual circuit test
initial begin
	$display($time, "     Starting...");

	$display($time, "  Starting detectors");
	reset = 1;
	// Reset before capturing events
	#100 reset = 0;
	#100 activate = 1;

	#430000 $stop;
end

endmodule

