module seconds_clock (
    input CLK,
    input NRST,

    output sec_inc
);

reg [24:0] timer;

always @ (posedge CLK) begin
    if (!NRST)
        timer <= 25'd0;
    else if (timer > 25'd27_000_000)
        timer <= 25'd0;
    else
        timer <= timer + 1'b1;
end

assign sec_inc = (timer == 25'd27_000_000) ? 1'b1 : 1'b0; // ~400kHz

endmodule