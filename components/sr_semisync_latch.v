module sr_semisync_latch(S, R, Q);
input S;
input R;
output reg Q = 0;

always@(posedge S, posedge R)
begin
if(S)
Q <= 1;
// Prioritize set to avoid the positive clock dominating half of each period
else if(R)
Q <= 0;
end
endmodule 