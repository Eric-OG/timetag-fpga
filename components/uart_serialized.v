module uart_serialized
#(parameter DATA_WIDTH_BYTES = 6, parameter CLKS_PER_BIT = 173)
(
	clk,
	reset,
	data_in,
	trigger,
	tx_out,
	transmission_over // Shows that the transmission ended during 1 clock cycle
);

localparam STATE_SIZE = 3;
localparam  
	RESET = 0,
	WAIT_FOR_TRIGGER = 1,
	LOAD_WORD = 2,
	SEND_BYTE = 3,
	WAIT_BYTE = 4,
	SHIFT_WORD = 5,
	TRANSM_OVER = 6;

input clk;
input reset;
input [DATA_WIDTH_BYTES*8-1:0] data_in;
input trigger;
output tx_out;
output reg transmission_over;

// UART module signals
reg uart_send;
wire [7:0] curr_uart_byte;
wire uart_done;

// Bytes counter signals
reg counter_reset;
reg counter_up;
wire counter_over;

// Finite state machine states
reg [STATE_SIZE-1:0] state = RESET;

// Shift register used to assign bytes to be transmitted
reg [DATA_WIDTH_BYTES*8-1:0] word_shift_reg;
assign curr_uart_byte = word_shift_reg[7:0];

uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) uart_byte_transmitter
    (.i_Clock(clk),
     .i_Tx_DV(uart_send),
     .i_Tx_Byte(curr_uart_byte),
     .o_Tx_Serial(tx_out),
     .o_Tx_Done(uart_done)
    );

counter #(DATA_WIDTH_BYTES) bytes_counter
    (.clk(clk),
     .reset(counter_reset),
     .up(counter_up),
     .count_over(counter_over)
    );

// State transition logic
always @(posedge clk) begin
    if (reset) begin
    	state = RESET;
	end
	else begin
	case (state)
		RESET:
			state = WAIT_FOR_TRIGGER;
		WAIT_FOR_TRIGGER:
			if(trigger)
				state = LOAD_WORD;
		LOAD_WORD:
			state = SEND_BYTE;
		SEND_BYTE:
			state = WAIT_BYTE;
		WAIT_BYTE:
			if(uart_done)
				if(counter_over)
					state = TRANSM_OVER;
				else
					state = SHIFT_WORD;
		SHIFT_WORD:
			state = SEND_BYTE;
		TRANSM_OVER:
			state = WAIT_FOR_TRIGGER;
	endcase
	end


end

// Dataflow logic
always @(state) 
begin
    case (state)
		RESET: begin
			counter_reset <= 1;
			counter_up <= 0;
			uart_send <= 0;
			transmission_over <= 0;
		end

		WAIT_FOR_TRIGGER: begin
			counter_reset <= 1;
			counter_up <= 0;
			uart_send <= 0;
			transmission_over <= 0;
		end

		LOAD_WORD: begin
			counter_reset <= 0;
			word_shift_reg <= data_in;
		end

		SEND_BYTE: begin
			counter_up <= 1;
			uart_send <= 1;
		end

		WAIT_BYTE: begin
			counter_up <= 0;
			uart_send <= 0;
		end

		SHIFT_WORD: begin
			word_shift_reg <= word_shift_reg >> 8;
		end
		
		TRANSM_OVER:
			transmission_over <= 1;

		default: begin
			counter_reset <= 0;
			counter_up <= 0;
			uart_send <= 0;
			transmission_over <= 0;
		end
    endcase
end

endmodule
