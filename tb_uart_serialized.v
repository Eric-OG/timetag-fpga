`timescale 1ns/10ps
 
module tb_uart_serialized();
    parameter CLOCK_PERIOD_NS = 50;
    parameter DATA_WIDTH_BYTES = 6; 
    localparam DATA_WIDTH_BITS = DATA_WIDTH_BYTES*8;

    reg clk = 1'b0;
    reg reset;
    reg[DATA_WIDTH_BITS-1:0] uart_data_in;
    reg uart_trigger;
    wire uart_tx_out;
    wire uart_transmission_over;

    uart_serialized #(.CLKS_PER_BIT(173), .DATA_WIDTH_BYTES(6)) dut
    (.clk(clk),
     .reset(reset),
     .data_in(uart_data_in),
     .trigger(uart_trigger),
     .tx_out(uart_tx_out),
     .transmission_over(uart_transmission_over)
    );
 
    always
        #(CLOCK_PERIOD_NS/2) clk <= !clk;
    initial
    begin
        reset <= 1'b1;
        @(posedge clk);
        reset <= 1'b0;
        @(posedge clk);
        uart_trigger <= 1'b1;
        uart_data_in <= 48'hEF0504030201;
        @(posedge clk);
        uart_trigger <= 1'b0;
        @(posedge uart_transmission_over);
        #10
        uart_data_in <= 48'hFF0908070605;
        uart_trigger <= 1'b1;
        @(posedge clk);
        @(posedge uart_transmission_over);
        #10
        $stop;
    end
   
endmodule