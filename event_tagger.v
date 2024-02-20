// Fast Multisource Pulse Registration System
// Module:
// event_tagger
// Pulse Registration and Time Stamping
// (c) Sergey V. Polyakov 2006-forever

// Modified By Eric O. Gomes 2024

module event_tagger
#(parameter N_CHANNELS = 4)
(
	strobe_channels,
	clk,
	reset_counter,
	capture_operate, counter_operate,
	data,
	ready
);

localparam DATA_WIDTH = 43 + N_CHANNELS;

input [N_CHANNELS-1:0] strobe_channels;
wire [N_CHANNELS-1:0] strobe_channels_treated;

input clk;
input reset_counter;
input capture_operate;
input counter_operate;

output ready; 
output [46:0] data;

reg [35:0] timer = 36'b0;

reg ready = 0;
reg [DATA_WIDTH-1:0] data = 0;

genvar i;
generate
	for (i = 0; i<N_CHANNELS; i=i+1) begin
		strobe_latch latch (clk, strobe_channels[i], strobe_channels_treated[i]);
	end
endgenerate

always @(posedge clk)
begin
	if (strobe_channels_treated != 4'b0 || (timer == 36'b0 && counter_operate))
	begin
		data[35:0] <= timer[35:0];
		data[36+N_CHANNELS-1:36] <= strobe_channels_treated;
		data[40+N_CHANNELS:36+N_CHANNELS] <= 0;				// reserved
		data[41+N_CHANNELS] <= 0;					// record type
		data[42+N_CHANNELS] <= (timer==36'b0) ? 1'b1 : 1'b0;	// wraparound
		ready <= capture_operate;
	end
	else
	begin
		ready <= 0;
		data <= 0;
	end
	
	timer <= reset_counter ? 0 : timer + counter_operate;
end



endmodule
