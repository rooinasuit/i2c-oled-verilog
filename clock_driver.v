module clock_driver (
    input CLK,
    input NRST,
    
    input sec_inc,

    // output reg colon,
    output reg [6:0] hr,
    output reg [6:0] min,
    output reg [6:0] sec
);

reg [2:0] hr1;
reg [3:0] hr0;

reg [2:0] min1;
reg [3:0] min0;

reg [2:0] sec1;
reg [3:0] sec0;

always @ (posedge CLK) begin
    hr <= {hr1, hr0};
    min <= {min1, min0};
    sec <= {sec1, sec0};
end

always @ (posedge CLK) begin
    if (!NRST) begin
        hr1 <= 3'd0;
        hr0 <= 4'd0;
        //
        min1 <= 3'd0;
        min0 <= 4'd0;
        //
        sec1 <= 3'd0;
        sec0 <= 4'd0;
    end
    else if (hr1 == 3'd2 && hr0 > 4'd3) begin
        hr1 <= 2'd0;
        hr0 <= 4'd0;
        //
        min1 <= 3'd0;
        min0 <= 4'd0;
        //
        sec1 <= 3'd0;
        sec0 <= 4'd0;
    end
    else if (hr1 < 3'd2 && hr0 > 4'd9) begin
        hr1 <= hr1 + 1'b1;
        hr0 <= 4'd0;
    end
    else if (min1 > 4'd5) begin
        hr0 <= hr0 + 1'b1;
        min1 <= 3'd0;
    end
    else if (min0 > 4'd9) begin
        min1 <= min1 + 1'b1;
        min0 <= 4'd0;
    end
    else if (sec1 > 4'd5) begin
        min0 <= min0 + 1'b1;
        sec1 <= 3'd0;
    end
    else if (sec0 > 4'd9) begin
        sec1 <= sec1 + 1'b1;
        sec0 <= 4'd0;
    end
    else if (posedge sec_inc) begin
        sec0 <= sec0 + 1'b1;
    end
end

endmodule