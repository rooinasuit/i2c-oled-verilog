module i2c_oled_setup (
    input CLK,
    input NRST,
    
    input [3:0] state,

    input [4:0] command_queue,
    input [8:0] data_queue,

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

// let's make an HH:MM:SS clock outta this :)

// AFTER INIT COMMANDS:
// 1) send a sequence of data bytes into the GDDRAM of oled,
// 2) send another sequence of pure ram data every time a change in the
// data output of the clock occurs (every 1s)


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
                                reg_addr <= 8'h40; // Set Display Start Line (0)
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
                                reg_addr <= 8'hE3; // NOP (one cycle before switching over to writing into ram)
                                //
                                control_select <= 2'b11; // multiple data frames will follow (mode commands for init needed?)
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
                case (data_queue)
                    //code x00
                    9'h000: data_write = 8'b00000000; // 
                    9'h001: data_write = 8'b00000000; // 
                    9'h002: data_write = 8'b01111100; //  *****
                    9'h003: data_write = 8'b11000110; // **   **
                    9'h004: data_write = 8'b11000110; // **   **
                    9'h005: data_write = 8'b11001110; // **  ***
                    9'h006: data_write = 8'b11011110; // ** ****
                    9'h007: data_write = 8'b11110110; // **** **
                    9'h008: data_write = 8'b11100110; // ***  **
                    9'h009: data_write = 8'b11000110; // **   **
                    9'h00a: data_write = 8'b11000110; // **   **
                    9'h00b: data_write = 8'b01111100; //  *****
                    9'h00c: data_write = 8'b00000000; // 
                    9'h00d: data_write = 8'b00000000; // 
                    9'h00e: data_write = 8'b00000000; // 
                    9'h00f: data_write = 8'b00000000; // 
                    //code x01
                    9'h010: data_write = 8'b00000000; // 
                    9'h011: data_write = 8'b00000000; // 
                    9'h012: data_write = 8'b00011000; // 
                    9'h013: data_write = 8'b00111000; // 
                    9'h014: data_write = 8'b01111000; //    **
                    9'h015: data_write = 8'b00011000; //   ***
                    9'h016: data_write = 8'b00011000; //  ****
                    9'h017: data_write = 8'b00011000; //    **
                    9'h018: data_write = 8'b00011000; //    **
                    9'h019: data_write = 8'b00011000; //    **
                    9'h01a: data_write = 8'b00011000; //    **
                    9'h01b: data_write = 8'b01111110; //    **
                    9'h01c: data_write = 8'b00000000; //    **
                    9'h01d: data_write = 8'b00000000; //  ******
                    9'h01e: data_write = 8'b00000000; // 
                    9'h01f: data_write = 8'b00000000; // 
                    //code x02
                    9'h020: data_write = 8'b00000000; // 
                    9'h021: data_write = 8'b00000000; // 
                    9'h022: data_write = 8'b01111100; //  *****
                    9'h023: data_write = 8'b11000110; // **   **
                    9'h024: data_write = 8'b00000110; //      **
                    9'h025: data_write = 8'b00001100; //     **
                    9'h026: data_write = 8'b00011000; //    **
                    9'h027: data_write = 8'b00110000; //   **
                    9'h028: data_write = 8'b01100000; //  **
                    9'h029: data_write = 8'b11000000; // **
                    9'h02a: data_write = 8'b11000110; // **   **
                    9'h02b: data_write = 8'b11111110; // *******
                    9'h02c: data_write = 8'b00000000; // 
                    9'h02d: data_write = 8'b00000000; // 
                    9'h02e: data_write = 8'b00000000; // 
                    9'h02f: data_write = 8'b00000000; // 
                    //code x03
                    9'h030: data_write = 8'b00000000; // 
                    9'h031: data_write = 8'b00000000; // 
                    9'h032: data_write = 8'b01111100; //  *****
                    9'h033: data_write = 8'b11000110; // **   **
                    9'h034: data_write = 8'b00000110; //      **
                    9'h035: data_write = 8'b00000110; //      **
                    9'h036: data_write = 8'b00111100; //   ****
                    9'h037: data_write = 8'b00000110; //      **
                    9'h038: data_write = 8'b00000110; //      **
                    9'h039: data_write = 8'b00000110; //      **
                    9'h03a: data_write = 8'b11000110; // **   **
                    9'h03b: data_write = 8'b01111100; //  *****
                    9'h03c: data_write = 8'b00000000; // 
                    9'h03d: data_write = 8'b00000000; // 
                    9'h03e: data_write = 8'b00000000; // 
                    9'h03f: data_write = 8'b00000000; // 
                    //code x04
                    9'h040: data_write = 8'b00000000; // 
                    9'h041: data_write = 8'b00000000; // 
                    9'h042: data_write = 8'b00001100; //     **
                    9'h043: data_write = 8'b00011100; //    ***
                    9'h044: data_write = 8'b00111100; //   ****
                    9'h045: data_write = 8'b01101100; //  ** **
                    9'h046: data_write = 8'b11001100; // **  **
                    9'h047: data_write = 8'b11111110; // *******
                    9'h048: data_write = 8'b00001100; //     **
                    9'h049: data_write = 8'b00001100; //     **
                    9'h04a: data_write = 8'b00001100; //     **
                    9'h04b: data_write = 8'b00011110; //    ****
                    9'h04c: data_write = 8'b00000000; // 
                    9'h04d: data_write = 8'b00000000; // 
                    9'h04e: data_write = 8'b00000000; // 
                    9'h04f: data_write = 8'b00000000; // 
                    //code x05
                    9'h050: data_write = 8'b00000000; // 
                    9'h051: data_write = 8'b00000000; // 
                    9'h052: data_write = 8'b11111110; // *******
                    9'h053: data_write = 8'b11000000; // **
                    9'h054: data_write = 8'b11000000; // **
                    9'h055: data_write = 8'b11000000; // **
                    9'h056: data_write = 8'b11111100; // ******
                    9'h057: data_write = 8'b00000110; //      **
                    9'h058: data_write = 8'b00000110; //      **
                    9'h059: data_write = 8'b00000110; //      **
                    9'h05a: data_write = 8'b11000110; // **   **
                    9'h05b: data_write = 8'b01111100; //  *****
                    9'h05c: data_write = 8'b00000000; // 
                    9'h05d: data_write = 8'b00000000; // 
                    9'h05e: data_write = 8'b00000000; // 
                    9'h05f: data_write = 8'b00000000; // 
                    //code x06
                    9'h060: data_write = 8'b00000000; // 
                    9'h061: data_write = 8'b00000000; // 
                    9'h062: data_write = 8'b00111000; //   ***
                    9'h063: data_write = 8'b01100000; //  **
                    9'h064: data_write = 8'b11000000; // **
                    9'h065: data_write = 8'b11000000; // **
                    9'h066: data_write = 8'b11111100; // ******
                    9'h067: data_write = 8'b11000110; // **   **
                    9'h068: data_write = 8'b11000110; // **   **
                    9'h069: data_write = 8'b11000110; // **   **
                    9'h06a: data_write = 8'b11000110; // **   **
                    9'h06b: data_write = 8'b01111100; //  *****
                    9'h06c: data_write = 8'b00000000; // 
                    9'h06d: data_write = 8'b00000000; // 
                    9'h06e: data_write = 8'b00000000; // 
                    9'h06f: data_write = 8'b00000000; // 
                    //code x07
                    9'h070: data_write = 8'b00000000; // 
                    9'h071: data_write = 8'b00000000; // 
                    9'h072: data_write = 8'b11111110; // *******
                    9'h073: data_write = 8'b11000110; // **   **
                    9'h074: data_write = 8'b00000110; //      **
                    9'h075: data_write = 8'b00000110; //      **
                    9'h076: data_write = 8'b00001100; //     **
                    9'h077: data_write = 8'b00011000; //    **
                    9'h078: data_write = 8'b00110000; //   **
                    9'h079: data_write = 8'b00110000; //   **
                    9'h07a: data_write = 8'b00110000; //   **
                    9'h07b: data_write = 8'b00110000; //   **
                    9'h07c: data_write = 8'b00000000; // 
                    9'h07d: data_write = 8'b00000000; // 
                    9'h07e: data_write = 8'b00000000; // 
                    9'h07f: data_write = 8'b00000000; // 
                    //code x08
                    9'h080: data_write = 8'b00000000; // 
                    9'h081: data_write = 8'b00000000; // 
                    9'h082: data_write = 8'b01111100; //  *****
                    9'h083: data_write = 8'b11000110; // **   **
                    9'h084: data_write = 8'b11000110; // **   **
                    9'h085: data_write = 8'b11000110; // **   **
                    9'h086: data_write = 8'b01111100; //  *****
                    9'h087: data_write = 8'b11000110; // **   **
                    9'h088: data_write = 8'b11000110; // **   **
                    9'h089: data_write = 8'b11000110; // **   **
                    9'h08a: data_write = 8'b11000110; // **   **
                    9'h08b: data_write = 8'b01111100; //  *****
                    9'h08c: data_write = 8'b00000000; // 
                    9'h08d: data_write = 8'b00000000; // 
                    9'h08e: data_write = 8'b00000000; // 
                    9'h08f: data_write = 8'b00000000; // 
                    //code x09
                    9'h090: data_write = 8'b00000000; // 
                    9'h091: data_write = 8'b00000000; // 
                    9'h092: data_write = 8'b01111100; //  *****
                    9'h093: data_write = 8'b11000110; // **   **
                    9'h094: data_write = 8'b11000110; // **   **
                    9'h095: data_write = 8'b11000110; // **   **
                    9'h096: data_write = 8'b01111110; //  ******
                    9'h097: data_write = 8'b00000110; //      **
                    9'h098: data_write = 8'b00000110; //      **
                    9'h099: data_write = 8'b00000110; //      **
                    9'h09a: data_write = 8'b00001100; //     **
                    9'h09b: data_write = 8'b01111000; //  ****
                    9'h09c: data_write = 8'b00000000; // 
                    9'h09d: data_write = 8'b00000000; // 
                    9'h09e: data_write = 8'b00000000; // 
                    9'h09f: data_write = 8'b00000000; // 
                    //code x10
                    9'h100: data_write = 8'b00000000; // 
                    9'h101: data_write = 8'b00000000; // 
                    9'h102: data_write = 8'b00000000; // 
                    9'h103: data_write = 8'b00000000; // 
                    9'h104: data_write = 8'b00011000; //    **
                    9'h105: data_write = 8'b00011000; //    **
                    9'h106: data_write = 8'b00000000; // 
                    9'h107: data_write = 8'b00000000; // 
                    9'h108: data_write = 8'b00000000; // 
                    9'h109: data_write = 8'b00011000; //    **
                    9'h10a: data_write = 8'b00011000; //    **
                    9'h10b: data_write = 8'b00000000; // 
                    9'h10c: data_write = 8'b00000000; // 
                    9'h10d: data_write = 8'b00000000; // 
                    9'h10e: data_write = 8'b00000000; // 
                    9'h10f: data_write = 8'b00000000; //
                    default: data_write = 8'b00000000;
                endcase
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