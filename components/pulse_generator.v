`timescale 1ps/1ps

// LENGTH_DELAY: number of delay not pairs for the pulse generation
module pulse_generator 
#(parameter LENGTH_DELAY = 1)
(
    out_signal,
    in_signal
);
    input in_signal;
    output out_signal;

    wire ff_out_q;
    wire ff_out_q_delayed;

    delay_line #(LENGTH_DELAY) delay_gen(ff_out_q_delayed, ff_out_q);

    d_flip_flop ff(
        .D(ff_out_q),
        .Q(ff_out_q),
        .clk(in_signal)
    );

    xor #(280) (out_signal, ff_out_q, ff_out_q_delayed);
    
endmodule
