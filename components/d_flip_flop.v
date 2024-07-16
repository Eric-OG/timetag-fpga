module d_flip_flop(D, Q, clk);
input D;
input clk; 
output reg Q = 0;

always @(posedge clk) 
begin
 Q <= ~D; 
end 
endmodule