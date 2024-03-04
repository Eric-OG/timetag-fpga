module counter
#(parameter COUNT_NUM = 1)
(
    clk,
    reset,
    up, // Triggers counting
    count_over // High when the count is over
);
input clk;
input reset;
input up;
output count_over;

reg [$clog2(COUNT_NUM)-1:0] count_val;

// up counter
always @(posedge clk or posedge reset)
begin
if(reset)
 count_val <= 0;
else if(up)
 count_val <= count_val + 1;
end 

assign count_over = (count_val == COUNT_NUM) ? 1'b1 : 1'b0;
endmodule