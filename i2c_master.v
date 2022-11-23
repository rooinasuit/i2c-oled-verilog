module i2c_master (
    input CLK,
    input NRST,

    input SCL_PULSE, // 400k clock from pll

    input ENABLE, // start the transaction

    input [6:0] slave_addr, // choose the slave
    input read_write, // read of write to slave?

    input [1:0] control_select, // what control frame to send
    input co_flag, // should the control frame be sent?
    
    input [7:0] control_frame, // control frame to slave
    input [7:0] reg_addr, // reg addr to slave
    input [7:0] data_write, // data to slave if WRITE

    // output reg [7:0] data_from_slave, // data from slave if READ

    output reg [3:0] state, // for tracking both here and in parallel modules

    output reg [4:0] command_queue, // pointer to command frame queue
    output reg [8:0] data_queue, // pointer to data frame queue

    inout scl,
    inout sda
);

localparam IDLE = 4'd0; // sda == 1 and scl == 1
localparam START = 4'd1; // sda 1->0 while scl == 1
localparam RECOGNITION = 4'd2; // request slave by address [0, 1, 1, 1, 1, 0, 0/1, R/W#]
localparam WRITE_CONTROL = 4'd3; // R/W# == 0 for writing bytes of data to slave
localparam WRITE_COMMAND = 4'd4; // D/C# == 0 for command
localparam WRITE_DATA = 4'd5; // D/C# == 1 for data into GDDRAM
localparam READ = 4'd6; // R/W# == 1 for reading bytes of data from slave (not in i2c)
localparam ACKNOWLEDGE = 4'd7; // sda -> 0 while scl == 0, slave acknowledges each control- or data-byte
localparam RECOGNITION_ACK = 4'd8; // ACKNOWLEDGE state exclusively for slave address
localparam STOP = 4'd9; // sda 0->1 while scl == 1


wire scl_out_en;
wire sda_out_en; 

assign scl_out_en = (state != IDLE);
assign sda_out_en = (state != IDLE && state != READ && state != RECOGNITION_ACK && state != ACKNOWLEDGE);

reg scl_high;
reg sda_high;

assign scl = scl_out_en ? scl_high : 1'bz; // whether to allow    
assign sda = sda_out_en ? sda_high : 1'bz; // master to transmit
                                           // logic '1' on scl_/sda_high is 1'bz either way 
reg transmission_en; // enable buffer
reg [7:0] slave_addr_out; // slave_addr buffer
reg [7:0] control_frame_out; // control_frame buffer
reg [7:0] command_write_out; // reg_addr buffer
reg [7:0] data_write_out; // data_write buffer

reg ack; // ack or nack from a slavea

reg [1:0] bus_timing; // monitor whether to switch logic of scl or sda
reg [4:0] bit_counter; // monitor the current number of bits sent/received in each frame

// !! SDA MUST NOT CHANGE ITS LOGIC LEVEL WHILE SCL IS ACTIVE

reg [3:0] next_state; // for when there's more than one condition to check before switching

always @ (posedge CLK) begin
    if (!NRST) begin
        scl_high <= 1;
        sda_high <= 1;
        //
        transmission_en <= 0;
        //
        slave_addr_out <= 0;
        control_frame_out <= 0;
        command_write_out <= 0;
        data_write_out <= 0;
        //
        ack <= 0;
        //
        bus_timing <= 0;
        bit_counter <= 8;
        //
        command_queue <= 0;
        data_queue <= 0;
        //
        state <= IDLE;
        next_state <= IDLE;
    end
    else begin
        if(SCL_PULSE) begin
            case(state)
                IDLE: begin
                    scl_high <= 1;
                    sda_high <= 1;
                    //
                    slave_addr_out <= 0;
                    control_frame_out <= 0;
                    command_write_out <= 0;
                    data_write_out <= 0;
                    //
                    bit_counter <= 8;
                    bus_timing <= 0;
                    if (!ENABLE) begin
                        state <= START;
                    end
                end
                START: begin
                    case (bus_timing)
                        0: begin
                            sda_high <= 0;
                            //
                            bit_counter <= 8;
                            bus_timing <= 1;
                        end
                        1: begin
                            scl_high <= 0;
                            bus_timing <= 2;
                        end
                        2: begin
                            bus_timing <= 3;
                        end
                        3: begin
                            slave_addr_out <= {slave_addr, read_write};
                            //
                            bus_timing <= 0;
                            //
                            state <= RECOGNITION;
                        end
                    endcase
                end
                RECOGNITION: begin
                    case (bus_timing)
                        0: begin
                            sda_high <= slave_addr_out[bit_counter - 1'b1];
                            //
                            bus_timing <= 1;
                        end
                        1: begin
                            scl_high <= 1;
                            //
                            bus_timing <= 2;
                        end
                        2: begin
                            scl_high <= 0;
                            //
                            bit_counter <= bit_counter - 1'b1;
                            bus_timing <= 3;
                        end
                        3: begin
                            if (bit_counter == 0) begin
                                case (sda_high)
                                    0: begin
                                        bit_counter <= 8;
                                        bus_timing <= 0;
                                        //
                                        state <= RECOGNITION_ACK;
                                        next_state <= WRITE_CONTROL;
                                    end
                                    1: begin
                                        bit_counter <= 8;
                                        bus_timing <= 0;
                                        //
                                        state <= RECOGNITION_ACK;
                                        next_state <= READ;
                                    end
                                endcase
                            end
                            else begin
                                bus_timing <= 0;
                            end
                        end
                    endcase
                end
                WRITE_CONTROL: begin
                    case (bus_timing)
                        0: begin
                            sda_high <= control_frame_out[bit_counter - 1'b1];
                            //
                            bus_timing <= 1;
                        end
                        1: begin
                            scl_high <= 1;
                            //
                            bus_timing <= 2;
                        end
                        2: begin
                            scl_high <= 0;
                            //
                            bit_counter <= bit_counter - 1'b1;
                            bus_timing <= 3;
                        end
                        3: begin
                            if (bit_counter == 0) begin
                                bit_counter <= 8;
                                bus_timing <= 0;
                                //
                                state <= ACKNOWLEDGE;
                            end
                            else if (bit_counter == 6) begin
                                case (sda_high)
                                    0: begin
                                        //
                                        bus_timing <= 0;
                                        //
                                        next_state <= WRITE_COMMAND;
                                    end
                                    1: begin
                                        //
                                        bus_timing <= 0;
                                        //
                                        next_state <= WRITE_DATA;
                                    end
                                endcase
                            end
                            else begin
                                bus_timing <= 0;
                            end
                        end
                    endcase
                end
                WRITE_COMMAND: begin
                    case (bus_timing)
                        0: begin
                            sda_high <= command_write_out[bit_counter - 1'b1];
                            //
                            bus_timing <= 1;
                        end
                        1: begin
                            scl_high <= 1;
                            //
                            bus_timing <= 2;
                        end
                        2: begin
                            scl_high <= 0;
                            //
                            bit_counter <= bit_counter - 1'b1;
                            bus_timing <= 3;
                        end
                        3: begin
                            if (bit_counter == 0) begin
                                command_queue <= command_queue + 1'b1;
                                //
                                bit_counter <= 8;
                                bus_timing <= 0;
                                //
                                next_state <= WRITE_CONTROL;
                                state <= ACKNOWLEDGE;
                            end
                            else begin
                                bus_timing <= 0;
                            end
                        end
                    endcase
                end
                WRITE_DATA: begin
                    case (bus_timing)
                        0: begin
                            sda_high <= data_write_out[bit_counter - 1'b1];
                            //
                            bus_timing <= 1;
                        end
                        1: begin
                            scl_high <= 1;
                            //
                            bus_timing <= 2;
                        end
                        2: begin
                            scl_high <= 0;
                            //
                            bit_counter <= bit_counter - 1'b1;
                            bus_timing <= 3;
                        end
                        3: begin
                            if (bit_counter == 0) begin
                                //
                                //data_queue <= data_queue + 1'b1;
                                // DOBOR DANYCH NA WYSYL BEDZIE SELEKTYWNY
                                //
                                bit_counter <= 8;
                                bus_timing <= 0;
                                //
                                next_state <= WRITE_CONTROL;
                                state <= ACKNOWLEDGE;
                            end
                            else begin
                                bus_timing <= 0;
                            end
                        end
                    endcase
                end
                //READ: begin
                //    case (bus_timing)
                //        0: begin

                //        end
                //        1: begin

                //        end
                //        2: begin
                        
                //        end
                //        3: begin

                //        end
                //    endcase
                //end
                RECOGNITION_ACK: begin
                    case (bus_timing)
                    0: begin
                        scl_high <= 1;
                        //
                        bus_timing <= 1;
                    end
                    1: begin
                        if (sda == 1) begin
                            ack <= 0; // nack if high
                            //
                            bus_timing <= 2;
                        end
                        else if (sda == 0) begin
                            ack <= 1; // ack if low
                            //
                            control_frame_out <= control_frame;
                            command_write_out <= reg_addr;
                            data_write_out <= data_write;
                            //
                            bus_timing <= 2;
                        end
                    end
                    2: begin
                        scl_high <= 0;
                        //
                        bus_timing <= 3;
                    end
                    3: begin
                        if (ack) begin
                            ack <= 0;
                            //
                            bus_timing <= 0;
                            //
                            state <= next_state;
                        end
                        else begin
                            state <= STOP; // <= IDLE
                        end
                    end
                    endcase
                end
                ACKNOWLEDGE: begin
                    case (bus_timing)
                    0: begin
                        scl_high <= 1;
                        //
                        bus_timing <= 1;
                    end
                    1: begin
                        if (sda == 1) begin
                            ack <= 0; // nack if high
                            //
                            bus_timing <= 2;
                        end
                        else if (sda == 0) begin
                            ack <= 1; // ack if low
                            //
                            control_frame_out <= control_frame;
                            command_write_out <= reg_addr;
                            data_write_out <= data_write;
                            //
                            bus_timing <= 2;
                        end
                    end
                    2: begin
                        scl_high <= 0;
                        //
                        bus_timing <= 3;
                    end
                    3: begin
                        if (ack) begin
                            ack <= 0;
                            //
                            case (control_select)
                                2'b00: state <= next_state;
                                2'b01: begin
                                    if (co_flag)
                                        state <= WRITE_COMMAND;
                                    else
                                        state <= next_state;
                                end
                                2'b10: state <= next_state;
                                2'b11: begin
                                    if (co_flag)
                                        state <= WRITE_DATA;
                                    else
                                        state <= next_state;
                                end
                            endcase
                            //
                            bus_timing <= 0;
                        end
                        else begin
                            state <= STOP; // <= IDLE
                        end
                    end
                    endcase
                    // did we get ACK?
                    // if yes, then state <= next_state (in case of single data byte)
                    //              state <= WRITE_COMMAND/WRITE_DATA (in case of multiple data bytes)
                    // if not, attempt to stop (IDLE)
                end
                STOP: begin
                    case (bus_timing)
                        0: begin
                            scl_high <= 1;
                            //
                            bus_timing <= 1;
                        end
                        1: begin
                            if (scl == 1)
                                bus_timing <= 2;
                            else
                                bus_timing <= 1;
                        end
                        2: begin
                            sda_high <= 1;
                            //
                            bus_timing <= 3;
                        end
                        3: begin
                            bus_timing <= 0;
                            //
                            state <= IDLE;
                        end
                    endcase
                end
                default: begin
                    scl_high <= 1;
                    sda_high <= 1;
                    //
                    slave_addr_out <= 0;
                    control_frame_out <= 0;
                    command_write_out <= 0;
                    data_write_out <= 0;
                    //
                    bit_counter <= 8;
                    bus_timing <= 0;
                    if (!ENABLE) begin
                        state <= START;
                    end
                end
            endcase
        end
    end
end

endmodule