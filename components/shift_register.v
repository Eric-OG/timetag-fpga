module shift_register #(
    parameter SIZE = 32
)(
    input wire clk,
    input wire reset,            // Asynchronous reset
    input wire load,             // Load the data_in into the register
    input wire shift_enable,
    input wire [SIZE-1:0] data_in, // Data input
    output reg [SIZE-1:0] data_out // Data output
);

always @(posedge clk or posedge reset or posedge load) begin
    if (reset) begin
        data_out <= {SIZE{1'b0}}; // Reset output to 0
    end
    else if (load) begin
        data_out <= data_in;
    end
    else if (shift_enable) begin
        data_out <= {8'b0, data_out[SIZE-1:8]}; // Shift right by 1 byte
    end
    else
        data_out <= data_out;
end

endmodule