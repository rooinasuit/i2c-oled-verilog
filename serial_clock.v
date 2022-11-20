module serial_clock (
    input CLK,
    input NRST,
    
    output SCL
);

reg [6:0] timer;

always @ (posedge CLK) begin
    if (!NRST)
        timer <= 7'd0;
    else if (timer > 7'd67)
        timer <= 7'd0;
    else
        timer <= timer + 1'b1;
end

assign SCL = (timer == 67) ? 1'b1 : 1'b0; // ~400kHz

endmodule