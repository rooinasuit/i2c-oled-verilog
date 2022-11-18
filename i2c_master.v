module i2c_master (
    input CLK,
    input NRST,

    input SCL_PULSE, // 400k clock from pll

    input enable, // start the transaction

    input [6:0] slave_addr, // choose the slave
    input read_write, // read of write to slave?

    input [7:0] control_frame, // control frame to slave
    input [7:0] reg_addr, // reg addr to slave
    input [7:0] data_write, // data to slave if WRITE

    // output reg [7:0] data_from_slave, // data from slave if READ

    output reg [3:0] state = IDLE, // for tracking both here and in parallel modules
    output reg [7:0] control_queue; // pointer to control frame queue
    output reg [7:0] command_queue; // pointer to command frame queue
    output reg [7:0] data_queue; // pointer to data frame queue

    inout scl,
    inout sda
);

localparam IDLE = 4'd0; // sda == 1 and scl == 1
localparam START = 4'd1; // sda 1->0 while scl == 1
localparam RECOGNITION = 4'd2; // request slave by address [0, 1, 1, 1, 1, 0, 0/1, R/W#]
localparam WRITE_CONTROL = 4'd3; // R/W# == 0 for writing bytes of data to slave
localparam WRITE_COMMAND = 4'd4; // D/C# == 0 for command
localparam WRITE_DATA = 4'd5; // D/C# == 1 for data into GDDRAM
localparam READ = 4'd6; // R/W# == 1 for reading bytes of data from slave
localparam ACKNOWLEDGE = 4'd7; // sda -> 0 while scl == 0, slave acknowledges each control- or data-byte
localparam STOP = 4'd8 // sda 0->1 while scl == 1

reg scl_out_en;
reg sda_out_en;

assign scl_out_en = (state != IDLE && bus_timing != 1)
assign sda_out_en = (state != IDLE && state != READ && state != ACKNOWLEDGE)

reg scl_high;
reg sda_high;

assign scl = scl_out_en ? scl_high : 1'bz; // whether to allow    
assign sda = sda_out_en ? sda_high : 1'bz; // master to transmit
                                           // logic '1' on scl_/sda_high is 1'bz either way 
reg transmission_en; // enable buffer
reg [7:0] slave_addr_out; // slave_addr buffer
reg [7:0] control_frame_out; // control_frame buffer
reg [7:0] reg_addr_out; // reg_addr buffer
reg [7:0] master_data_out; // master_data buffer

reg ack; // ack or nack from a slave

reg [1:0] bus_timing; // monitor whether to switch logic of scl or sda
reg [3:0] bit_counter; // monitor the current number of bits sent/received in each frame

// !! SDA MUST NOT CHANGE ITS LOGIC LEVEL WHILE SCL IS ACTIVE

reg [4:0] next_state; // for when there's more than one condition to check before switching

always @ (posedge CLK) begin
    if (!NRST) begin
        scl_high <= 1;
        sda_high <= 1;
        transmission_en <= 0;
        slave_addr_out <= 0;
        reg_addr_out <= 0;
        master_data_out <= 0;
        ack <= 0;
        bus_timing <= 0;
        bit_counter <= 7;
        control_queue <= 0;
        command_queue <= 0;
        data_queue <= 0;
        state <= IDLE;
        next_state <= IDLE;
    end
    else begin
        if(SCL_PULSE) begin
            //if (state != (IDLE || STOP)) 
            //    bus_timing <= bus_timing + 1;
            //else if (state == ACKNOWLEDGE && ack == 0)
            //    bus_timing <= bus_timing;
            //else if (bus_timing > 2'b11)
            //    bus_timing <= 2'd0;
            case(state)
                IDLE: begin
                    scl_high <= 1;
                    sda_high <= 1;                    
                    //////////////
                    transmission_en <= enable;
                    //////////////
                    bus_timing <= 0;
                    if (transmission_en) begin
                        state <= START;
                    end
                end
                START: begin
                    case (bus_timing)
                        0: begin
                            transmission_en <= 0;
                            bit_counter <= 7;
                            bus_timing <= 1;
                        end
                        1: begin
                            sda_high <= 0;
                            bus_timing <= 2;
                        end
                        2: begin
                            scl_high <= 0;
                            bus_timing <= 3;
                        end
                        3: begin
                            bus_timing <= 0;
                            state <= RECOGNITION;
                        end
                    endcase
                end
                RECOGNITION: begin
                    if (bit_counter == 7) begin
                        slave_addr_out <= {slave_addr, read_write};
                    end
                    case (bus_timing)
                        0: begin
                            sda_high <= slave_addr_out[bit_counter]; 
                            bit_counter <= bit_counter - 1;
                            bus_timing <= 1;
                        end
                        1: begin
                            scl_high <= 1;
                            bus_timing <= 2;
                        end
                        2: begin
                            scl_high <= 0;
                            bus_timing <= 3;
                        end
                        3: begin
                            if (bit_counter == 0) begin
                                case (sda_high)
                                    0:
                                        next_state <= WRITE_CONTROL;
                                    1:
                                        next_state <= READ;
                                endcase
                                bit_counter <= 7;
                                bus_timing <= 0;
                                state <= ACKNOWLEDGE;
                            end
                            else
                                bus_timing <= 0;
                        end
                    endcase
                end
                WRITE_CONTROL: begin
                    if (bit_counter == 7) begin
                        control_frame_out <= control_frame;
                    end
                    case (bus_timing)
                        0: begin
                            sda_high <= control_frame_out[bit_counter];
                            bit_counter <= bit_counter - 1;
                            bus_timing <= 1;
                        end
                        1: begin
                            scl_high <= 1;
                            bus_timing <= 2;
                        end
                        2: begin
                            scl_high <= 0;
                            bus_timing <= 3;
                        end
                        3: begin
                            if (bit_counter == 0) begin
                                bit_counter <= 7;
                                control_queue <= control_queue + 1;
                                bus_timing <= 0;
                                state <= ACKNOWLEDGE;
                            end
                            else if (bit_counter == 6) begin
                                case (sda_high)
                                    0:
                                        next_state <= WRITE_COMMAND;
                                    1:
                                        next_state <= WRITE_DATA;
                                endcase
                                bus_timing <= 0; 
                            end
                            else
                                bus_timing <= 0;
                        end
                    endcase
                    // first frame is control
                    // second is data or command
                    // depending on Co and D/C#
                end
                WRITE_COMMAND: begin
                    if (bit_counter == 7) begin
                        reg_addr_out <= reg_addr;
                    end
                    case (bus_timing)
                        0: begin
                            sda_high <= reg_addr_out[bit_counter];
                            bit_counter <= bit_counter - 1;
                            bus_timing <= 1;
                        end
                        1: begin
                            scl_high <= 1;
                            bus_timing <= 2;
                        end
                        2: begin
                            scl_high <= 0;
                            bus_timing <= 3;
                        end
                        3: begin
                            if (bit_counter == 0) begin
                                bit_counter <= 7;
                                command_queue <= command_queue + 1;
                                bus_timing <= 0;
                                next_state <= WRITE_CONTROL;
                                state <= ACKNOWLEDGE;
                            end
                            else
                                bus_timing <= 0;
                        end
                    endcase
                end
                WRITE_DATA: begin
                    if (bit_counter == 7) begin
                        master_data_out <= master_data;
                    end
                    case (bus_timing)
                        0: begin
                            sda_high <= master_data_out[bit_counter];
                            bit_counter <= bit_counter - 1;
                            bus_timing <= 1;
                        end
                        1: begin
                            scl_high <= 1;
                            bus_timing <= 2;
                        end
                        2: begin
                            scl_high <= 0;
                            bus_timing <= 3;
                        end
                        3: begin
                            if (bit_counter == 0) begin
                                bit_counter <= 7;
                                data_queue <= data_queue + 1;
                                bus_timing <= 0;
                                next_state <= WRITE_CONTROL;
                                state <= ACKNOWLEDGE;
                            end
                            else
                                bus_timing <= 0;
                        end
                    endcase
                end
                READ: begin
                    case (bus_timing)
                        0: begin

                        end
                        1: begin

                        end
                        2: begin
                        
                        end
                        3: begin

                        end
                    endcase
                end
                ACKNOWLEDGE: begin
                    case (bus_timing)
                    0: begin
                        scl_high <= 1;
                        bus_timing <= 1;
                    end
                    1: begin
                        if (sda == 1) begin
                            ack <= 0; // nack if high
                        end
                        bus_timing <= 2;
                    end
                    2: begin
                        scl_high <= 0;
                        if (sda == 0) begin
                            ack <= 1; // ack if low
                        end
                        bus_timing <= 3;
                    end
                    3: begin
                        if (ack) begin
                            state <= next_state;
                            ack <= 0;
                        end
                        else begin
                            state <= STOP; // <= IDLE
                        end
                        bus_timing <= 0;
                    end
                    endcase
                    // did we get ACK?
                    // if yes, then state <= next_state
                    // if not, attempt to stop (IDLE)
                end
                STOP: begin
                    case (bus_timing)
                        0: begin
                            scl_high <= 1;
                            bus_timing <= 1;
                        end
                        1: begin
                            if (scl == 1)
                                bus_timing <= 2;
                        end
                        2: begin
                            sda_high <= 1;
                            bus_timing <= 3;
                        end
                        3: begin
                            state <= IDLE;
                            bus_timing <= 0;
                        end
                    endcase
                end
                default: begin
                    scl_high <= 1;
                    sda_high <= 1;                    
                    //////////////
                    transmission_en <= enable;
                    //////////////
                    bus_timing <= 0;
                    if (transmission_en) begin
                        state <= START;
                    end
                end
            endcase
        end
    end
end

endmodule