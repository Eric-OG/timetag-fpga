module sr_latch(input S, input R, output reg Q, output reg Q_bar);
    always @(S, R) begin
        if (R && !S)       // Reset condition
            begin
                Q <= 0;
                Q_bar <= 1;
            end
        else if (!R && S)  // Set condition
            begin
                Q <= 1;
                Q_bar <= 0;
            end
        else if (R && S)   // Invalid condition
            begin
                // Indeterminate state, hold previous state
            end
    end
endmodule