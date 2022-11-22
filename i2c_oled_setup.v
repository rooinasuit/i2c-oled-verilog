module i2c_oled_setup (
    input CLK,
    input NRST,
    
    input [3:0] state,

    input [4:0] command_queue,
    input [7:0] data_queue,

    output reg [6:0] slave_addr,
    output reg read_write,

    output reg [7:0] control_frame,
    output reg [7:0] reg_addr,
    output reg [7:0] data_write,

    output reg [1:0] control_select,
    output reg co_flag
);

localparam IDLE = 4'd0; // sda == 1 and scl == 1
localparam START = 4'd1; // sda 1->0 while scl == 1
localparam RECOGNITION = 4'd2; // request slave by address [0, 1, 1, 1, 1, 0, 0/1, R/W#]
localparam WRITE_CONTROL = 4'd3; // R/W# == 0 for writing bytes of data to slave
localparam WRITE_COMMAND = 4'd4; // D/C# == 0 for command
localparam WRITE_DATA = 4'd5; // D/C# == 1 for data into GDDRAM
localparam READ = 4'd6; // R/W# == 1 for reading bytes of data from slave
localparam ACKNOWLEDGE = 4'd7; // sda -> 0 while scl == 0, slave acknowledges each control- or data-byte
localparam RECOGNITION_ACK = 4'd8; // ACKNOWLEDGE state exclusively for slave address
localparam STOP = 4'd9; // sda 0->1 while scl == 1

reg frame_timing;

always @ (posedge CLK) begin 
    if (!NRST) begin
        control_select <= 1;
        co_flag <= 0;
        //
        frame_timing <= 0;
    end
    else begin
        case (state)
            START: begin // only oled (write) for the time being
                slave_addr <= 7'b0111100;
                read_write <= 1'b0;
            end
            ACKNOWLEDGE: begin
                case (control_select)
                    2'b00: control_frame <= 8'h80; // single command frame
                    2'b01: control_frame <= 8'h00; // multiple command frames
                    2'b10: control_frame <= 8'hC0; // single data frame
                    2'b11: control_frame <= 8'h40; // multiple data frames
                endcase
                //
                case (command_queue)
                    5'd0: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b01;
                                co_flag <= 0;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'hA8; // Set Mux Ratio
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end
                    5'd1: begin
                        case (frame_timing)
                            0: begin
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'h3F; // **
                                //
                                frame_timing <= 0;
                            end
                        endcase  
                    end
                    //
                    5'd2: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b01;
                                co_flag <= 0;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'hD3; // Set Display Offset
                                //
                                frame_timing <= 0;
                            end
                        endcase 
                    end
                    5'd3: begin
                        case (frame_timing)
                            0: begin
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'h00; // **
                                //
                                frame_timing <= 0;
                            end
                        endcase 
                    end
                    //
                    5'd4: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b00;
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'h40; // Set Display Start Line
                                //
                                frame_timing <= 0;
                            end
                        endcase 
                    end
                    //
                    5'd5: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b00;
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'hA0; // Set Segment remap
                                //
                                frame_timing <= 0;
                            end
                        endcase 
                    end
                    //
                    5'd6: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b00;
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'hC0; // Set COM Out Scan Dir
                                //
                                frame_timing <= 0;
                            end
                        endcase 
                    end
                    //
                    5'd7: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b01;
                                co_flag <= 0;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'hDA; // Set COM Pins Hardware Config
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end
                    5'd8: begin
                        case (frame_timing)
                            0: begin
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'h02; // **
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end
                    //
                    5'd9: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b01;
                                co_flag <= 0;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'h81; // Set Contrast Control
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end
                    5'd10: begin
                        case (frame_timing)
                            0: begin
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'h7F; // **
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end

                    5'd11: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b00;
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'hA4; // Disable Entire Display ON
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end

                    5'd12: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b00;
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'hA6; // Set Normal Display
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end

                    5'd13: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b01;
                                co_flag <= 0;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'hD5; // Set Osc Freq
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end
                    5'd14: begin
                        case (frame_timing)
                            0: begin
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'h80; // **
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end

                    5'd15: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b01;
                                co_flag <= 0;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'h8D; // Enable Charge Pump Regulator
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end
                    5'd16: begin
                        case (frame_timing)
                            0: begin
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'h14; // **
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end

                    5'd17: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b00;
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'hAF; // Display ON
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end

                    5'd18: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b00;
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'hA5; // Entire Display ON
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end
                    default: begin
                        case (frame_timing)
                            0: begin
                                control_select <= 2'b00;
                                co_flag <= 1;
                                //
                                frame_timing <= 1;
                            end
                            1: begin
                                reg_addr <= 8'hE3; // NOP
                                //
                                frame_timing <= 0;
                            end
                        endcase
                    end  
                endcase
        //    end
            //WRITE_DATA: begin
            //    case (data_queue)
            //
            //    endcase
            //end
        //    default: begin
        //    slave_addr <= 0;
        //    read_write <= 0;
        //    control_frame <= 0;
        //    reg_addr <= 0;
        //    data_write <= 0;
        //    end
            end
        endcase
    end 
end

// [*]    => single byte command
// [**]   => double byte command
// [***]  => triple byte command
// [~XX#] => multiple variant byte command (up to XX)

// /////////////////
// // RECOGNITION //
//                //                                        0/1   W/R          
//     8'h78: spread => {1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0}; // OLED WRITE
//     8'h79: spread => {1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1}; // OLED READ

// ///////////////////
// // WRITE_CONTROL //
//                //    Co    D/C#
//     8'h00: spread => {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // OLED COMMAND
//     8'h80: spread => {1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // OLED DATA->REG
    
// ///////////////////////////////
// // OLED COMMANDS (D/C# == 0) //

// // FUNDAMENTALS //
//                //     A7    A6    A5    A4    A3    A2    A1    A0
//     8'h81: spread => {1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; // [**] Set Contrast Control

//                //                                               X0
//     8'hA4: spread => {1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0}; // [*] Entire Display ON Resume To Ram 
//     8'hA5: spread => {1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1}; // [*] Entire Display ON

//                //                                               X0
//     8'hA6: spread => {1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0}; // [*] Set Normal Display [1 => Pixel ON]
//     8'hA7: spread => {1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1}; // [*] Set Inverse DIsplay [1 => Pixel OFF]

//                //                                               X0
//     8'hAE: spread => {1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b1, 1'b0}; // [*] Set Display OFF
//     8'hAF: spread => {1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1}; // [*] Set DIsplay ON

// // ADDRESSING //
//                //                             X3    X2    X1    X0
//     8'h00: spread => {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // [~0F#] Set Lower Column Start Address For Page Addressing Mode: 0 (RESET)
//     8'h10: spread => {1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0}; // [~1F#] Set Higher Column Start Address For Page Addressing Mode: 0 (RESET)

//                //                                         A1    A0           
//     8'h20: spread => {1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // [**] Set Memory Addressing Mode: Page Addressing, 2'b10 (RESET)

//                //           A6    A5    A4    A3    A2    A1    A0  (Start, 0 (RESET))
//                //           B6    B5    B4    B3    B2    B1    B0  (End, 127 (RESET))
//     8'h21: spread => {1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; // [***] Set Column Address

//                //                                   A2    A1    A0 (Start, 0 (RESET))
//                //                                   B2    B1    B0 (End, 7 (RESET))
//     8'h22: spread => {1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0}; // [***] Set Page Address

//                //                                   X2    X1    X0
//     8'hB0: spread => {1'b1, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0}; // [~B7#] Set Page Start Address For Page Addressing Mode
    
// // HARDWARE CONFIGS //
//                //                 X5    X4    X3    X2    X1    X0   
//     8'h40: spread => {1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // [~7F#] Set Display Start Line: 0 (RESET)

//                //                                               X0
//     8'hA0: spread => {1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // [*] Set Segment Remap (Column 0)
//     8'hA1: spread => {1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; // [*] Set Segment Remap (Column 127)

//                //                 A5    A4    A3    A2    A1    A0
//     8'hA8: spread => {1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0}; // [**] Set Multiplex Ratio: 64MUX (RESET)

//                //                             X3
//     8'hC0: spread => {1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // [*] Set COM Out Scan Dir: 0 (0->127 (RESET))
//     8'hC8: spread => {1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0}; // [*] Set COM Out Scan Dir: 1 (127->0 (RESET))

//                //                 A5    A4    A3    A2    A1    A0
//     8'hD3: spread => {1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b1}; // [**] Set Display Offset: 0 (RESET)

//                //                 A5    A4    1'b0
//     8'hDA: spread => {1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0}; // [**] Set COM Pins: Alternative Disable Left/Right Remap (RESET)

// // TIMING & DRIVING SCHEMES //

//                //     A7    A6    A5    A4    A3    A2    A1    A0
//     8'hD5: spread => {1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1}; // [**] Set Osc Freq [7:4]/Disp CLK Divide Ratio [3:0]
//     8'hD9: spread => {1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b0}; // [**] Set Precharge Period (Ph2 [7:4], Ph1 [3:0])

//                //     1'b0  A6    A5    A4    1'b0  1'b0  1'b0  1'b0
//     8'hDB: spread => {1'b1, 1'b1, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1, 1'b1}; // [**] Set Vcomh Deselect Level
//     8'hE3: spread => {1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1}; // [*] NOP

// // CHARGE PUMP //

//                //                 1'b0  1'b1  1'b0  A2    1'b0  1'b0
//     8'hD5: spread => {1'b1, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b1}; // [**] Charge Pump Setting

endmodule