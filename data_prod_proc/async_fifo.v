module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 32,
    parameter ADDR_WIDTH = 5 //$clog(32)
) (
    input wr_clk,
    input wr_rst_n,
    input wr_en,
    input [DATA_WIDTH-1:0] wr_data,
    output full,

    input rd_clk,
    input rd_rst_n,
    input rd_en,
    output [DATA_WIDTH-1:0] rd_data,
    output empty
);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1]; //Dual port ram to store pixels
//Binary pointer for read and write - One extra bit to identify fifo full condition 
reg [ADDR_WIDTH:0] wr_ptr_bin;
reg [ADDR_WIDTH:0] rd_ptr_bin;
//Gray encoded pointer for write and read
wire [ADDR_WIDTH:0] wr_ptr_gray;
wire [ADDR_WIDTH:0] rd_ptr_gray;
//Binary to gray code conversion
assign wr_ptr_gray = wr_ptr_bin ^ (wr_ptr_bin >> 1);
assign rd_ptr_gray = rd_ptr_bin ^ (rd_ptr_bin >> 1);

// Synchronized gray pointers
reg [ADDR_WIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;  
reg [ADDR_WIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;  

assign full = (wr_ptr_gray == {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
assign empty = (rd_ptr_gray == wr_ptr_gray_sync2);


always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        wr_ptr_bin <= 0;
    end else if (wr_en && !full) begin
        mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data; //Use only lower 5 bits for address as sixth bit is checking wrap around
        wr_ptr_bin <= wr_ptr_bin + 1;
    end
end
    
reg [DATA_WIDTH-1:0] rd_data_reg;
    
always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        rd_ptr_bin <= 0;
        rd_data_reg <= 0;
    end else if (rd_en && !empty) begin
        rd_data_reg <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
        rd_ptr_bin <= rd_ptr_bin + 1;
    end
end
    
assign rd_data = rd_data_reg;

always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        wr_ptr_gray_sync1 <= 0;
        wr_ptr_gray_sync2 <= 0;
    end else begin
        wr_ptr_gray_sync1 <= wr_ptr_gray;
        wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
end

always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        rd_ptr_gray_sync1 <= 0;
        rd_ptr_gray_sync2 <= 0;
    end else begin
        rd_ptr_gray_sync1 <= rd_ptr_gray;
        rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
end

endmodule
