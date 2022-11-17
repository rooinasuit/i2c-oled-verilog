module main (
    input CLK,
    input NRST,
    
    inout scl,
    inout sda
);

// !! DODAC ENABLE DLA MASTERA

wire SCL_PULSE;

wire slave_addr;
wire read_write;

wire control_frame;
wire reg_addr;
wire data_write

Gowin_rPLL PLL(
    .clkout(CLK), //output clkout 27M
    .clkoutd(SCL_PULSE), //output clkoutd 400k - 2%
    .clkin(clkin_i) //input clkin 27M
);
 
i2c_master i2c_master1 (
    .CLK (CLK),
    .NRST (NRST),
    .SCL_PULSE (SCL_PULSE),
    .enable (enable),
    .slave_addr (slave_addr),
    .read_write (read_write),
    .control_frame (control_frame),
    .reg_addr (reg_addr),
    .data_write (data_write),
    .scl (scl),
    .sda (sda)
);

i2c_oled_setup i2c_oled_setup (
    .CLK (CLK),
    .NRST (NRST),
    .slave_addr (slave_addr),
    .read_write (read_write),
    .control_frame (control_frame),
    .reg_addr (reg_addr),
    .data_write (data_write),
);