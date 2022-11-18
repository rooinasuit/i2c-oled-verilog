module main (
    input CLK,
    input NRST,
    
    inout scl_bus,
    inout sda_bus
);

// !! DODAC ENABLE DLA MASTERA

wire SCL_PULSE;

wire [6:0] slave_addr;
wire read_write;

wire [7:0] control_frame;
wire [7:0] reg_addr;
wire [7:0] data_write

wire [3:0] state

wire [7:0] control_queue;
wire [7:0] command_queue;
wire [7:0] data_queue;

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
    .state (state),
    .control_queue (control_queue),
    .command_queue (command_queue),
    .data_queue (data_queue),
    .scl (scl_bus),
    .sda (sda_bus)
);

i2c_oled_setup i2c_oled_setup (
    .CLK (CLK),
    .NRST (NRST),
    .state (state),
    .control_queue (control_queue),
    .command_queue (command_queue),
    .data_queue (data_queue),
    .slave_addr (slave_addr),
    .read_write (read_write),
    .control_frame (control_frame),
    .reg_addr (reg_addr),
    .data_write (data_write),
);