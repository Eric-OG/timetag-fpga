module timetagger_100(
	strobe_channels,
	clk,
	reset,
	activate,
	tx_out,
	
	// debug outputs
	db_strobe_c_0,
	db_activate_engine,
	db_reset_timetag_counter,
	db_record_rdy,
	db_uart_send,
	db_rec_buf_empty,
	db_rec_buf_full,
	db_uart_done
);

localparam STATE_SIZE = 4;
localparam  
	RESET = 0,
	WAIT_FOR_ACTIVATE = 1,
    ACTIVATE = 2,
    WAIT_RECORD = 3,
	READ_FIFO = 4,
    SEND_WORD = 5,
	WAIT_WORD = 6;

input [99:0] strobe_channels;
input clk;
input reset;
input activate;
output tx_out;

output db_strobe_c_0;
output db_activate_engine;
output db_reset_timetag_counter;
output db_record_rdy;
output db_uart_send;
output db_rec_buf_empty;
output db_rec_buf_full;
output db_uart_done;


// Tagger engine signals
reg activate_engine;
reg reset_timetag_counter;
wire [142:0] record;
wire record_rdy;

// Buffer signals
reg clr_buf;
reg rec_buf_rdnext;
wire rec_buf_full;
wire rec_buf_empty;
wire [143:0] rec_buf_out;

// UART signals
reg reset_uart;
reg uart_send;
wire uart_done;

// Finite state machine states
reg [STATE_SIZE-1:0] state = RESET;

event_tagger #(.N_CHANNELS(100)) tag_engine
(
	.strobe_channels(strobe_channels),
	.clk(clk),
	.reset_counter(reset_timetag_counter),
	.capture_operate(activate_engine), 
	.counter_operate(activate_engine),
	.data(record),
	.ready(record_rdy)
);

fifo_18_bytes rec_buf(
	.aclr(clr_buf),
	.wrclk(clk),
	.wrreq(record_rdy && !rec_buf_full),
	.wrfull(rec_buf_full),
	.data({1'b0, record}),

	.rdclk(clk),
	.rdreq(rec_buf_rdnext),
	.rdempty(rec_buf_empty),
	.q(rec_buf_out)
);

uart_serialized #(.CLKS_PER_BIT(2604), .DATA_WIDTH_BYTES(18)) uart_transmitter (
	.clk(clk),
    .reset(reset_uart),
    .data_in(rec_buf_out),
    .trigger(uart_send),
    .tx_out(tx_out),
    .transmission_over(uart_done)
);

// State transition logic
always @(posedge clk) begin
    if (reset) begin
    	state <= RESET;
	end
	else begin
		case (state)
			RESET:
				state = WAIT_FOR_ACTIVATE;
			WAIT_FOR_ACTIVATE:
				if(activate)
					state = ACTIVATE;
			ACTIVATE:
				state = WAIT_RECORD;
			WAIT_RECORD:
				if(activate & (~rec_buf_empty))
					state = READ_FIFO;
				else if (~activate)
					state = WAIT_FOR_ACTIVATE;
			READ_FIFO:
				state = SEND_WORD;
			SEND_WORD:
				state = WAIT_WORD;
			WAIT_WORD:
				if(uart_done) begin
					if(activate)
						state = WAIT_RECORD;
					else
						state = WAIT_FOR_ACTIVATE;
				end
				else
					state = WAIT_WORD;
		endcase
	end


end

// Dataflow logic
always @(state) 
begin
    case (state)
		RESET: begin
			clr_buf <= 1;
			reset_timetag_counter <= 1;
			reset_uart <= 1;
			activate_engine <= 0;
			uart_send <= 0;
			rec_buf_rdnext <= 0;
		end

		WAIT_FOR_ACTIVATE: begin
			clr_buf <= 0;
			reset_timetag_counter <= 0;
			reset_uart <= 0;
			activate_engine <= 0;
			uart_send <= 0;
			rec_buf_rdnext <= 0;
		end

		ACTIVATE: begin
			clr_buf <= 0;
			reset_timetag_counter <= 0;
			reset_uart <= 0;
			activate_engine <= 1;
			uart_send <= 0;
			rec_buf_rdnext <= 0;
		end

		WAIT_RECORD: begin
			clr_buf <= 0;
			reset_timetag_counter <= 0;
			reset_uart <= 0;
			activate_engine <= 1;
			uart_send <= 0;
			rec_buf_rdnext <= 0;
		end
		
		READ_FIFO: begin
			clr_buf <= 0;
			reset_timetag_counter <= 0;
			reset_uart <= 0;
			activate_engine <= 1;
			uart_send <= 0;
			rec_buf_rdnext <= 1;
		end

		SEND_WORD: begin
			clr_buf <= 0;
			reset_timetag_counter <= 0;
			reset_uart <= 0;
			activate_engine <= 1;
			uart_send <= 1;
			rec_buf_rdnext <= 0;
		end
		
		WAIT_WORD: begin
			clr_buf <= 0;
			reset_timetag_counter <= 0;
			reset_uart <= 0;
			activate_engine <= 1;
			uart_send <= 0;
			rec_buf_rdnext <= 0;
		end
			
		default: begin
			clr_buf <= 0;
			reset_timetag_counter <= 0;
			reset_uart <= 0;
			activate_engine <= 0;
			uart_send <= 0;
			rec_buf_rdnext <= 0;
		end
    endcase
end

// Debug signals
assign db_strobe_c_0 = strobe_channels[0];
assign db_activate_engine = activate_engine;
assign db_reset_timetag_counter = reset_timetag_counter;
assign db_record_rdy = record_rdy;
assign db_uart_send = uart_send;
assign db_rec_buf_empty = rec_buf_empty;
assign db_rec_buf_full = rec_buf_full;
assign db_uart_done = uart_done;


endmodule
