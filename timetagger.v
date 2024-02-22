module timetagger(
	strobe_channels,
	clk,
	reset,
	activate,
	tx_out
);

localparam STATE_SIZE = 4;
localparam  
	RESET = 0,
	WAIT_FOR_ACTIVATE = 1,
    ACTIVATE = 2,
    WAIT_RECORD = 3,
	READ_FIFO = 4,
    SEND_BYTE = 5,
	WAIT_BYTE = 6;

input [3:0] strobe_channels;
input clk;
input reset;
input activate;
output tx_out;

// Tagger engine signals
reg activate_engine;
reg reset_timetag_counter;
wire [46:0] record;
wire record_rdy;

// Buffer signals
reg clr_buf;
reg rec_buf_rdnext;
wire rec_buf_full;
wire rec_buf_empty;
wire [47:0] rec_buf_out;

// UART signals
reg uart_send;
reg [2:0] curr_byte_ctr;
reg [7:0] curr_uart_byte;
wire uart_is_active;
wire uart_done;

// Finite state machine states
reg [STATE_SIZE-1:0] state = RESET;

event_tagger #(.N_CHANNELS(4)) tag_engine
(
	.strobe_channels(strobe_channels),
	.clk(clk),
	.reset_counter(reset_timetag_counter),
	.capture_operate(activate_engine), 
	.counter_operate(activate_engine),
	.data(record),
	.ready(record_rdy)
);

sample_fifo rec_buf(
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

uart_tx #(.CLKS_PER_BIT(173)) UART_TX_INST
    (.i_Clock(clk),
     .i_Tx_DV(uart_send),
     .i_Tx_Byte(curr_uart_byte),
     .o_Tx_Active(uart_is_active),
     .o_Tx_Serial(tx_out),
     .o_Tx_Done(uart_done)
     );

// UART Byte multiplexer
always @(curr_byte_ctr) begin
  case (curr_byte_ctr)
    3'b000: curr_uart_byte = rec_buf_out[47:40];
    3'b001: curr_uart_byte = rec_buf_out[39:32];
    3'b010: curr_uart_byte = rec_buf_out[31:24];
    3'b011: curr_uart_byte = rec_buf_out[23:16];
    3'b100: curr_uart_byte = rec_buf_out[15:8];
    3'b101: curr_uart_byte = rec_buf_out[7:0];
    default: curr_uart_byte = 8'b00000000; // Default case, set output to 0 if select is out of range
  endcase
end

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
				if(activate) begin
					if(~rec_buf_empty)
						state = READ_FIFO;
				end
				else
					state = WAIT_FOR_ACTIVATE;
			READ_FIFO:
				state = SEND_BYTE;
			SEND_BYTE:
				state = WAIT_BYTE;
			WAIT_BYTE:
				if(uart_done) begin
					curr_byte_ctr = curr_byte_ctr + 1;
					if(curr_byte_ctr == 3'b110)
						if(activate)
							state = WAIT_RECORD;
						else
							state = WAIT_FOR_ACTIVATE;
					else
						state = SEND_BYTE;
				end
		endcase
	end


end

// Dataflow logic
always @(state) 
begin
    case (state)
		RESET: begin
			clr_buf = 1;
			reset_timetag_counter = 1;
			activate_engine = 0;
			uart_send = 0;
			rec_buf_rdnext = 0;
		end

		WAIT_FOR_ACTIVATE: begin
			clr_buf = 0;
			reset_timetag_counter = 0;
			activate_engine = 0;
			uart_send = 0;
			rec_buf_rdnext = 0;
		end

		ACTIVATE: begin
			clr_buf = 0;
			reset_timetag_counter = 0;
			activate_engine = 1;
			uart_send = 0;
			rec_buf_rdnext = 0;
		end

		WAIT_RECORD: 
			rec_buf_rdnext = 0;

		READ_FIFO: begin
			rec_buf_rdnext = 1;
			// Prepare to send bytes
			curr_byte_ctr = 0;
		end

		SEND_BYTE: begin
			rec_buf_rdnext = 0;
			uart_send = 1;
		end
		
		WAIT_BYTE:
			uart_send = 0;

		default: begin
			clr_buf = 0;
			reset_timetag_counter = 0;
			activate_engine = 0;
			uart_send = 0;
			rec_buf_rdnext = 0;
		end
    endcase
end

endmodule
