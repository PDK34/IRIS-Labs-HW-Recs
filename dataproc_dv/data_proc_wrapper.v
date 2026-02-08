/*
This module wraps both data_prod and data_proc, providing a
memory-mapped interface for the CPU to control them.
Register Map:
0x02001000 - CONTROL      [2:1]=mode, [0]=start  
0x02001004 - STATUS       [1]=valid_out, [0]=busy
0x02001008 - PIXEL_COUNT  [31:0]=pixels processed
0x0200100C - OUTPUT_DATA  [8]=valid, [7:0]=pixel
*/
`timescale 1ns/1ps

module dataproc_producer_wrapper (
    input clk,
    input resetn,
    
    // Memory bus interface (from rvsoc)
    input         mem_valid,
    output        mem_ready,
    input  [ 3:0] mem_wstrb,
    input  [31:0] mem_addr,
    input  [31:0] mem_wdata,
    output [31:0] mem_rdata
);

   
    parameter IMAGE_SIZE = 1024;
    

    wire control_sel    = mem_valid && (mem_addr == 32'h02001000);
    wire status_sel     = mem_valid && (mem_addr == 32'h02001004);
    wire pixcount_sel   = mem_valid && (mem_addr == 32'h02001008);
    wire output_sel     = mem_valid && (mem_addr == 32'h0200100C);
    
    wire reg_sel = control_sel || status_sel || pixcount_sel || output_sel;
    
    reg mem_ready_reg;
    always @(posedge clk) begin
        if (!resetn)
            mem_ready_reg <= 1'b0;
        else
            mem_ready_reg <= reg_sel && !mem_ready_reg;
    end
    assign mem_ready = mem_ready_reg;
    
    //CONTROL REGISTER(0x02001000) - R/W
    reg start_reg;
    reg [1:0] mode_reg;
    
    always @(posedge clk) begin
        if (!resetn) begin
            start_reg <= 1'b0;
            mode_reg  <= 2'b00;
        end else if (control_sel && mem_wstrb[0]) begin
            start_reg <= mem_wdata[0];
            mode_reg  <= mem_wdata[2:1];
        end
    end
    
    wire [31:0] control_rdata = {29'h0, mode_reg, start_reg};
    
    //STATUS REGISTER(0x02001004) - Read Only
    wire busy_flag;
    wire output_valid_flag;
    
    wire [31:0] status_rdata = {30'h0, output_valid_flag, busy_flag};
    
    //PIXEL COUNT REGISTER(0x02001008) - Read Only
    reg [31:0] pixel_count_reg;
    
    always @(posedge clk) begin
        if (!resetn)
            pixel_count_reg <= 32'h0;
        else if (!start_reg)
            pixel_count_reg <= 32'h0;
        else if (output_valid_flag && proc_ready_in)
            pixel_count_reg <= pixel_count_reg + 1;
    end
    
    wire [31:0] pixcount_rdata = pixel_count_reg;
    
    //OUTPUT DATA REGISTER(0x0200100C) - Read Only
    wire [7:0] output_pixel;
    
    wire [31:0] output_rdata = {23'h0, output_valid_flag, output_pixel};
    
    //READ DATA MUX
    assign mem_rdata = 
        control_sel   ? control_rdata   :
        status_sel    ? status_rdata    :
        pixcount_sel  ? pixcount_rdata  :
        output_sel    ? output_rdata    :
        32'h00000000;
    
    // data producer(runs on system clk in this case)
    wire [7:0] pixel_from_prod;
    wire valid_from_prod;
    wire ready_to_prod;
    
    data_prod #(
        .IMAGE_SIZE(IMAGE_SIZE)
    ) data_producer (
        .sensor_clk(clk),  //Uses same clk as system here   
        .rst_n(resetn),
        .ready(ready_to_prod && start_reg),
        .pixel(pixel_from_prod),
        .valid(valid_from_prod)
    );
    
    //Data processor
    wire proc_ready_out;
    wire proc_ready_in = 1'b1; //set always ready to accept output
    
    assign ready_to_prod = proc_ready_out;
    
    // Busy flag
    reg [1:0] proc_state;
    localparam IDLE = 2'b00, PROCESS = 2'b01;
    
    always @(posedge clk) begin
        if (!resetn)
            proc_state <= IDLE;
        else if (start_reg)
            proc_state <= PROCESS;
        else
            proc_state <= IDLE;
    end
    
    assign busy_flag = (proc_state == PROCESS);
    
    data_proc data_processor (
        .clk(clk), //Same clk as system here
        .rstn(resetn),
        
        .pixel_in(pixel_from_prod),
        .pixel_out(output_pixel),
        .VALID_IN(valid_from_prod && start_reg),
        .READY_OUT(proc_ready_out),
        .VALID_OUT(output_valid_flag),
        .READY_IN(proc_ready_in),
        
        .mode(mode_reg),
        .start(start_reg)
    );

endmodule
