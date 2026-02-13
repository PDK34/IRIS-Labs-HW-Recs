`timescale 1ns/1ps
module data_proc (
    input clk,
    input rstn,

    input [7:0] pixel_in,
    output reg [7:0] pixel_out,
    
    input VALID_IN,
    output READY_OUT,
    input READY_IN,
    output reg VALID_OUT,

    input [1:0] mode,
    input start
);

parameter IMG_WIDTH = 32;

//States
reg [1:0] state, next_state;
localparam [1:0] IDLE = 2'b00,
                 PROCESS = 2'b01;

// Line buffers
reg [7:0] line_buffer_0 [0:IMG_WIDTH-1];
reg [7:0] line_buffer_1 [0:IMG_WIDTH-1];
reg [7:0] line_buffer_2 [0:IMG_WIDTH-1];

integer i;
reg [1:0] row_count;
reg [$clog2(IMG_WIDTH)-1:0] col_count;
reg [11:0] conv_sum;
reg [8:0] conv_result;

assign READY_OUT = (state == PROCESS) && (!VALID_OUT || READY_IN);

//Sequential register logic
always @(posedge clk) begin
    if (!rstn) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

//Next state logic 
always @(*) begin
    next_state = state;
    case (state)
        IDLE: begin
            if (start) begin
                next_state = PROCESS;
            end
        end
        PROCESS: begin
            if (!start) begin
                next_state = IDLE;
            end
        end
        default: begin
            next_state = IDLE;
        end 
    endcase
end

//Data processing
always @(posedge clk) begin
    if (!rstn) begin
        pixel_out <= 8'd0;
        VALID_OUT <= 1'd0;
        col_count <= 0;
        row_count <= 0;
        conv_sum <= 0;
        conv_result <= 0;
        
        //Reset line buffers
        for (i = 0; i < IMG_WIDTH; i = i + 1) begin
            line_buffer_0[i] <= 8'd0;
            line_buffer_1[i] <= 8'd0;
            line_buffer_2[i] <= 8'd0;
        end
    end else begin
        //Clear VALID_OUT when data consumed
        if (VALID_OUT && READY_IN) begin
            VALID_OUT <= 1'b0;
        end
        
        case (state)
            IDLE: begin
                
                // Clear Valid flag when Idle to discard stale data
                VALID_OUT <= 1'b0; 
                
                if (next_state == PROCESS) begin
                    row_count <= 0;
                    col_count <= 0;
                end
            end
            
            PROCESS: begin
                if (VALID_IN && READY_OUT) begin
                    //Update pixel position counters 
                    if (col_count == IMG_WIDTH - 1) begin
                        col_count <= 0;
                        if (row_count < 3) 
                            row_count <= row_count + 1;
                    end else begin
                        col_count <= col_count + 1;
                    end
                    
                    // Update line buffers
                    if (mode == 2'b10) begin
                        line_buffer_0[col_count] <= pixel_in;
                        line_buffer_1[col_count] <= line_buffer_0[col_count];
                        line_buffer_2[col_count] <= line_buffer_1[col_count];
                    end

                    case (mode)
                        2'b00: begin  // Bypass 
                            pixel_out <= pixel_in;
                            VALID_OUT <= 1'b1;
                        end
                        
                        2'b01: begin  //Invert 
                            pixel_out <= ~pixel_in;
                            VALID_OUT <= 1'b1;
                        end
                        
                        2'b10: begin  // Convolution
                            if (row_count >= 2 && col_count >= 1) begin
                                conv_sum = 0;
                                
                                //Top row 
                                conv_sum = conv_sum + {8'h0, line_buffer_2[col_count-1]};
                                conv_sum = conv_sum + {8'h0, line_buffer_2[col_count]};
                                conv_sum = conv_sum + {8'h0, line_buffer_2[(col_count+1) % IMG_WIDTH]};
                                
                                //Middle row
                                conv_sum = conv_sum + {8'h0, line_buffer_1[col_count-1]};
                                conv_sum = conv_sum + {8'h0, line_buffer_1[col_count]};
                                conv_sum = conv_sum + {8'h0, line_buffer_1[(col_count+1) % IMG_WIDTH]};
                                
                                //Bottom row 
                                conv_sum = conv_sum + {8'h0, line_buffer_0[col_count-1]};
                                conv_sum = conv_sum + {8'h0, line_buffer_0[col_count]};
                                conv_sum = conv_sum + {8'h0, line_buffer_0[(col_count+1) % IMG_WIDTH]};
                                
                                conv_result = conv_sum >> 3;
                                
                                pixel_out <= (conv_result > 255) ? 8'hFF : conv_result[7:0];
                                VALID_OUT <= 1'b1;
                            end else begin
                                VALID_OUT <= 1'b0;
                            end
                        end
                        
                        default: begin
                            pixel_out <= 8'd0;
                            VALID_OUT <= 1'b0;
                        end
                    endcase
                end
            end
        endcase
    end
end
endmodule
