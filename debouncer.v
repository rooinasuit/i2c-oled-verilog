module debouncer (
    input CLK,
    input NRST,
    input CLK_EN,
    input key_in,
    
    output key_out
);

reg [14:0] data_out = 15'd0;

always @ (posedge CLK) begin
    if (!NRST)
        data_out <= 15'd0;
    else if (CLK_EN)
        data_out <= {data_out[13:0], key_in}; // shift register action
end

assign key_out = (&data_out[14:0]);

endmodule