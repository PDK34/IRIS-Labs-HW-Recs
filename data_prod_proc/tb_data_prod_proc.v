`timescale 1ns/1ps

module tb_data_prod_proc;

    reg clk = 0;
    reg sensor_clk = 0;

    // 100MHz
    always #5 clk = ~clk;

    // 200MHz
    always #2.5 sensor_clk = ~sensor_clk;

    reg [5:0] reset_cnt = 0;
    wire resetn = &reset_cnt;

    always @(posedge clk) begin
        if (!resetn)
            reset_cnt <= reset_cnt + 1'b1;
    end

    reg [5:0] sensor_reset_cnt = 0;
    wire sensor_resetn = &sensor_reset_cnt;

    always @(posedge sensor_clk) begin
        if (!sensor_resetn)
            sensor_reset_cnt <= sensor_reset_cnt + 1'b1;
    end

    wire [7:0] pixel_from_prod;
    wire valid_from_prod;

    wire fifo_full,fifo_empty;
    wire [7:0] pixel_from_fifo;



	// Processor output and control signals
    wire [7:0] pixel_out;
    wire valid_out;
    reg [1:0] mode;
    reg start;
    wire ready_to_fifo;
    
    //Debug signals
    integer output_file;
    integer pixel_count;

	data_prod data_producer (
        .sensor_clk(sensor_clk),
        .rst_n(sensor_resetn),
        .ready(!fifo_full),
        .pixel(pixel_from_prod),
        .valid(valid_from_prod)
	);    

    async_fifo #(
        .DATA_WIDTH(8),
        .DEPTH(32)
    ) fifo(
        .wr_clk(sensor_clk), //Input clock and other signals from and to producer
        .wr_rst_n(sensor_resetn),
        .wr_en(valid_from_prod&& !fifo_full),
        .wr_data(pixel_from_prod),
        .full(fifo_full),

        .rd_clk(clk), //Input clock and other signals from and to processing block
        .rd_rst_n(resetn),
        .rd_en(ready_to_fifo && !fifo_empty),
        .rd_data(pixel_from_fifo),
        .empty(fifo_empty)
    );

	data_proc data_processing (
        .clk(clk),
        .rstn(resetn),
        .pixel_in(pixel_from_fifo),
        .pixel_out(pixel_out),
        .VALID_IN(!fifo_empty),
        .READY_OUT(ready_to_fifo),
        .VALID_OUT(valid_out),
        .READY_IN(1'b1),//set always ready to accept output
        .mode(mode),
        .start(start)
	);



    always @(posedge clk) begin //Write output pixels to file for debugging purpose
    if (resetn && valid_out && pixel_count < 1024) begin
        $fwrite(output_file, "%02X\n", pixel_out);
        pixel_count = pixel_count + 1;
        end
    end

    initial begin
        mode = 2'b00;
        start = 0;
        pixel_count = 0;

        wait(resetn == 1);
        wait(sensor_resetn == 1);
      #100;

        mode = 2'b00; //Test bypass mode
        output_file = $fopen("output_bypass.hex", "w");
        pixel_count = 0;
        start = 1;      
        wait(pixel_count >= 1024);
        #100;     
       $fclose(output_file);
        start = 0;
        #200;

        mode = 2'b01;  //Test invert mode
        output_file = $fopen("output_invert.hex", "w");
        pixel_count = 0;
        start = 1;
        wait(pixel_count >= 1024);
        #100;      
        $fclose(output_file);
        start = 0;
        #200;

        mode = 2'b10;  //Test convolution mode
        output_file = $fopen("output_conv.hex", "w");
        pixel_count = 0;
        start = 1;
        wait(pixel_count >= 1024);
        #1000;      
        $fclose(output_file);
        start = 0;
        #200;

        mode = 2'b11;  //Test fourth mode which is not implemented
        start = 1;
        #1000;     
        if (valid_out == 0) begin
            $display("Mode 1'b11 correctly produces no output");
        end else begin
            $display("ERROR: Mode 1'b11 is not valid!");
        end  
        start = 0;
        #200;


    end

endmodule
