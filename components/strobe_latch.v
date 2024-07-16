/* Register the rising edge of a signal */
module strobe_latch (clk, in, out);

input clk;
input in;
output out;

// Register peak during a clock cycle, will only be shown in the next clock
wire peak_l_out;
wire delayed_clk;
wire pulse_detected;
wire out_inv;

// Delay for synchonization
delay_line #(2) clk_delay (delayed_clk, clk);

sr_semisync_latch peak_detec (
	.S(in),
	.R(delayed_clk),
	.Q(pulse_detected)
);

// By default the ff output is inverted
d_flip_flop output_ff (
	.D(pulse_detected),
	.Q(out_inv),
	.clk(clk)
);

assign out = ~out_inv;

endmodule
