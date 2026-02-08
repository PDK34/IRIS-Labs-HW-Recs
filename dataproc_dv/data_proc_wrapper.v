`timescale 1ns/1ps

module data_proc_wrapper (
    input clk,
    input resetn,
    //Bus interface (from rvsoc)
    input         mem_valid,
    output        mem_ready,
    input  [ 3:0] mem_wstrb,
    input  [31:0] mem_addr,
    input  [31:0] mem_wdata,
    output [31:0] mem_rdata
);
    wire control_sel   = mem_valid && (mem_addr == 32'h02001000);
    wire status_sel   = mem_valid && (mem_addr == 32'h02001004);
    wire pixcnt_sel   = mem_valid && (mem_addr == 32'h02001008);
    wire input_sel    = mem_valid && (mem_addr == 32'h0200100C);
    wire output_sel    = mem_valid && (mem_addr == 32'h02001010);
    
    // Any valid register access
    wire reg_sel = control_sel || status_sel || pixcount_sel || 
                   input_sel || output_sel;

endmodule
