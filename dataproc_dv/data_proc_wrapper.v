/*
This module interfaces processing block, providing a memory-mapped interface 
for the CPU to feed it data

Register Map:
0x02001000 - CONTROL      [2:1]=mode, [0]=start
0x02001004 - STATUS       [1]=valid_out, [0]=busy
0x02001008 - PIXEL_COUNT  [31:0]=pixels processed
0x0200100C - OUTPUT_DATA  [8]=valid, [7:0]=pixel
0x02001010 - INPUT_DATA   [7:0]=pixel (Write Only) <-- NEW
*/
`timescale 1ns/1ps

module data_proc_wrapper (
    input clk,
    input resetn,
    
    // Memory bus interface
    input         mem_valid,
    output        mem_ready,
    input  [ 3:0] mem_wstrb,
    input  [31:0] mem_addr,
    input  [31:0] mem_wdata,
    output [31:0] mem_rdata
);

    //Bus Interface Logic
    wire control_sel = mem_valid && (mem_addr == 32'h02001000);
    wire status_sel  = mem_valid && (mem_addr == 32'h02001004);
    wire count_sel   = mem_valid && (mem_addr == 32'h02001008);
    wire output_sel  = mem_valid && (mem_addr == 32'h0200100C);
    wire input_sel   = mem_valid && (mem_addr == 32'h02001010); // New Input Address

    assign mem_ready = (control_sel || status_sel || count_sel || output_sel || input_sel);

    //Control Registers
    reg [2:0] control_reg; 
    wire start_reg = control_reg[0];
    wire [1:0] mode_reg = control_reg[2:1];
    reg [31:0] pixel_count_reg;

    always @(posedge clk) begin
        if (!resetn) control_reg <= 0;
        else if (control_sel && mem_wstrb[0]) control_reg <= mem_wdata[2:0];
    end

    //Streaming Interface 
    reg [7:0] proc_pixel_in_reg;
    reg       proc_valid_in_reg;
    wire      proc_ready_out; // From core
    
    //When CPU writes to 0x02001010 assert VALID to the core
    always @(posedge clk) begin
        if (!resetn) begin
            proc_valid_in_reg <= 0;
            proc_pixel_in_reg <= 0;
        end else begin
            //If CPU writes new pixel
            if (input_sel && mem_wstrb[0]) begin
                proc_pixel_in_reg <= mem_wdata[7:0];
                proc_valid_in_reg <= 1'b1;
            end 
            else if (proc_ready_out) begin
                proc_valid_in_reg <= 1'b0;
            end
        end
    end

    
    wire [7:0] output_pixel;
    wire output_valid_flag;
    
    //Acknowledge read when CPU reads the output reg
    wire cpu_read_ack = output_sel && (mem_wstrb == 4'b0);

    always @(posedge clk) begin
        if (!resetn || !start_reg) pixel_count_reg <= 0;
        else if (output_valid_flag && cpu_read_ack) pixel_count_reg <= pixel_count_reg + 1;
    end

    data_proc #(.IMG_WIDTH(32)) data_processor (
        .clk(clk),
        .rstn(resetn),
        .pixel_in(proc_pixel_in_reg),
        .pixel_out(output_pixel),
        .VALID_IN(proc_valid_in_reg),
        .READY_OUT(proc_ready_out),
        .VALID_OUT(output_valid_flag),
        .READY_IN(cpu_read_ack), 
        .mode(mode_reg),
        .start(start_reg)
    );

    // -------------------------------------------------------------------------
    // 5. Read Data Mux
    // -------------------------------------------------------------------------
    reg [31:0] rdata_reg;
    always @(*) begin
        rdata_reg = 32'd0;
        if (control_sel) rdata_reg = {29'b0, control_reg};
        if (status_sel)  rdata_reg = {30'b0, output_valid_flag, !proc_ready_out};
        if (count_sel)   rdata_reg = pixel_count_reg;
        if (output_sel)  rdata_reg = {23'b0, output_valid_flag, output_pixel};
    end
    assign mem_rdata = rdata_reg;

endmodule
