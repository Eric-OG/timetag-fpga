`timescale 1ns/1ns

module tb_tagger_fifo();

reg clk;

wire [46:0] record;
wire record_rdy;
reg reset = 0;
reg activate_tagger = 0;
wire rec_buf_full;

reg [3:0] detectors;

reg rec_buf_rdnext;
wire rec_buf_empty;
wire [47:0] rec_buf_out;

event_tagger #(.N_CHANNELS(4)) uut
(
	.strobe_channels(detectors),
	.clk(clk),
	.reset_counter(reset),
	.capture_operate(activate_tagger), 
	.counter_operate(activate_tagger),
	.data(record),
	.ready(record_rdy)
);

sample_fifo rec_buf(
	.wrclk(clk),
	.wrreq(record_rdy && !rec_buf_full),
	.wrfull(rec_buf_full),
	.data({1'b0, record}),

	.rdclk(clk),
	.rdreq(rec_buf_rdnext),
	.rdempty(rec_buf_empty),
	.q(rec_buf_out)
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
	#200 detectors[0] = 1'b1;
	#5  detectors[0] = 1'b0;
end
`endif

`ifdef RANDOM_PEAKS
initial begin
	if ((4'b1111 & $random) == 4'b0)
	begin
		detectors[1] = 1'b1;
		#10 detectors[1] = 1'b0;
	end
end
`else
always begin
	#30 detectors[1] = 1'b1;
	#5  detectors[1] = 1'b0;
end
`endif

// These statements conduct the actual circuit test
initial begin
	$display($time, "     Starting...");

	$display($time, "  Starting detectors");
	#100 ;

	// Reset before capturing events
	activate_tagger = 0;
	#12 reset = 1;
	#12 reset = 0;
	// Start capturing events
	activate_tagger = 1;

	#200
	activate_tagger = 0;
	#12
	rec_buf_rdnext = 1;
	#30
	rec_buf_rdnext = 0;
	#30
	$stop;
end

endmodule
