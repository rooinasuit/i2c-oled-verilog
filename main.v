module main (
    input CLK,
    input NRST,
    
    input ENABLE,

    inout scl_bus,
    inout sda_bus
);

wire SCL_PULSE;

wire [6:0] slave_addr;
wire read_write;

wire [1:0] control_select;
wire co_flag;

wire [7:0] control_frame;
wire [7:0] reg_addr;
wire [7:0] data_write;

wire [3:0] state;

wire [4:0] command_queue;
wire [7:0] data_queue;

serial_clock serial_clock (
    .CLK (CLK),
    .NRST (NRST),
    .SCL (SCL_PULSE)
);

i2c_master i2c_master1 (
    .CLK (CLK),
    .NRST (NRST),
    .SCL_PULSE (SCL_PULSE),
    .ENABLE (ENABLE),
    .slave_addr (slave_addr),
    .read_write (read_write),
    .control_select (control_select),
    .co_flag (co_flag),
    .control_frame (control_frame),
    .reg_addr (reg_addr),
    .data_write (data_write),
    .state (state),
    .command_queue (command_queue),
    .data_queue (data_queue),
    .scl (scl_bus),
    .sda (sda_bus)
);

i2c_oled_setup i2c_oled_setup (
    .CLK (CLK),
    .NRST (NRST),
    .state (state),
    .command_queue (command_queue),
    .data_queue (data_queue),
    .slave_addr (slave_addr),
    .read_write (read_write),
    .control_frame (control_frame),
    .reg_addr (reg_addr),
    .data_write (data_write),
    .control_select (control_select),
    .co_flag (co_flag)
);

//debouncer enable_button (
//    .CLK (CLK),
//    .NRST (NRST),
//    .CLK_EN (SCL_PULSE),
//    .key_in (b1),
//    .key_out (enable)
//);
endmodule