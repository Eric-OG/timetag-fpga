`timescale 1ns/1ns

module tb_fifo_uart();

reg clk;
reg fx2_clk;

reg reg_wr;
reg [15:0] reg_addr;
wire [31:0] reg_data;
reg [31:0] reg_data_drive;

wire [15:0] length;
reg request_length;

wire [46:0] record;
wire record_rdy;
reg data_ack;

reg [3:0] detectors;
wire [3:0] laser_en;
wire running;

// Buffer signals
wire rec_buf_full;
reg rec_buf_rdnext = 0;
wire rec_buf_empty;
wire [47:0] rec_buf_out;

assign reg_data = reg_data_drive;

// Instantiate the UUT
apdtimer_all uut(
	.clk(clk),
	.strobe_in(detectors),

	.reg_clk(clk),
	.reg_addr(reg_addr),
	.reg_data(reg_data),
	.reg_wr(reg_wr),

	.record_rdy(record_rdy),
	.record(record)
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


// This just prints the results in the ModelSim text window
// You can leave this out if you want
initial
	$monitor($time, "  cmd(%b %x %x) data(%b %x)",
		reg_wr, reg_addr, reg_data,
		record_rdy, record,
	);

// Clocks
initial clk = 0;
always #2 clk = ~clk;
initial fx2_clk = 0;
always #6 fx2_clk = ~fx2_clk;

// Simulate photons
initial detectors = 4'b0000;
//`define RANDOM_PHOTONS
`ifdef RANDOM_PHOTONS
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

`ifdef RANDOM_PHOTONS
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

	// Reset procedure
	// Disable strobe channels
	#12  reg_addr=8'h04;
	#12  reg_data_drive=8'h00; reg_wr=1;
	// Disable delta channels
	#12  reg_addr=8'h05;
	     reg_data_drive=8'h00;
	// Reset counter and event generations
	#12  reg_addr=8'h03;
	     reg_data_drive=8'h04;
	// Unassert reset_counter
	#12  reg_addr=8'h03;
	     reg_data_drive=8'h00;

	// Begin capturing events
	// Enable all strobe channels
	#12  reg_addr=8'h04;
	     reg_data_drive=8'h0F;
	// Start counter and event generation
	#12  reg_addr=8'h03;
	     reg_data_drive=8'h03;

	#12  reg_wr=0;

	#300 rec_buf_rdnext = 1;
	#50 rec_buf_rdnext = 0;
	#100

	$stop;
end

endmodule

