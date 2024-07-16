`timescale 1ps/1ps

// LENGTH: number of pairs of inverter gates
module delay_line 
#(parameter LENGTH = 1)
(
    out_line,
    in_line
);
    input in_line;
    output out_line;

    wire [0:2*LENGTH] conn_line /*synthesis keep*/;

    assign conn_line[0] = in_line;
    assign out_line = conn_line[2*LENGTH];
    
    genvar i;
    generate
        for (i = 0; i<2*LENGTH; i=i+1) begin : gen_loop_block
            not #(280) (conn_line[i+1], conn_line[i]);
        end
    endgenerate
    
endmodule
