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

    reg force_sensor_reset = 1'b1;  //Start in reset, to fix pixels shifting across mode testing
    reg [5:0] sensor_reset_cnt = 0;
   // Reset is active when counter not full OR when forced
    wire sensor_resetn = &sensor_reset_cnt && !force_sensor_reset;


    always @(posedge sensor_clk) begin
        if (force_sensor_reset) begin
            sensor_reset_cnt <= 0;  //Hold in reset
        end else if (!sensor_resetn) begin
            sensor_reset_cnt <= sensor_reset_cnt + 1'b1;
          end
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
    integer total_outputs;  // Track ALL outputs


    //Control signal to stop producer between tests so that all pixels are ensured to be accessible while testing all modes
    reg producer_enable;

	data_prod data_producer (
        .sensor_clk(sensor_clk),
        .rst_n(sensor_resetn),
        .ready(!fifo_full && producer_enable),
        .pixel(pixel_from_prod),
        .valid(valid_from_prod)
	);    

    async_fifo #(
        .DATA_WIDTH(8),
        .DEPTH(32)
    ) fifo(
        .wr_clk(sensor_clk), //Input clock and other signals from and to producer
        .wr_rst_n(sensor_resetn),
        .wr_en(valid_from_prod&& !fifo_full && producer_enable),
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



    always @(posedge clk) begin
        if (resetn && valid_out) begin
            total_outputs = total_outputs + 1;            
            //Only write to file after skipping initial garbage/zero values
            if (total_outputs > 1 && pixel_count < 1024) begin
                $fwrite(output_file, "%02X\n", pixel_out);
                pixel_count = pixel_count + 1;
            end
        end
    end
    /*Task to flush fifo outputs and reset producer adn processor in between testing different
     modes ,dealing with initial pixel loss in modes which are tested later
    */
    task flush_fifo_and_reset;  
    integer flush_count;
    begin
        $display(" Flushing FIFO and Resetting Processor and producer");
        producer_enable = 0;
        start = 0;
        
        //Drain the FIFO
        flush_count = 0;
        while (!fifo_empty && flush_count < 100) begin
            @(posedge clk);
            flush_count = flush_count + 1;
        end 

        //Reset the producer
        force_sensor_reset = 1'b1;
        repeat(5) @(posedge sensor_clk);

        //Reset processor 
        // force the reset_cnt to 0 to trigger wire resetn = &reset_cnt;
        reset_cnt = 0; 
        repeat(5) @(posedge clk);
        
        //Release resets
        force_sensor_reset = 1'b0;
        
        // Wait for resets to clear 
        wait(resetn == 1); 
        wait(sensor_resetn == 1);
        
        repeat(10) @(posedge clk);
    end
endtask


    initial begin
        mode = 2'b00;
        start = 0;
        pixel_count = 0;
        total_outputs = 0;
        producer_enable = 0;

        force_sensor_reset = 1'b1;
        wait(resetn == 1);
        repeat(10) @(posedge clk);    
        //Release sensor reset
        force_sensor_reset = 1'b0;
        wait(sensor_resetn == 1);
       #100;

        mode = 2'b00; //Test bypass mode
        output_file = $fopen("output_bypass.hex", "w");
        pixel_count = 0;
        total_outputs = 0;
        start = 1;             
        #50;                  
        producer_enable = 1;   
        wait(pixel_count >= 1024);
        #100;     
       $fclose(output_file);
       flush_fifo_and_reset();
        start = 0;
        #300;

        mode = 2'b01;  //Test invert mode
        output_file = $fopen("output_invert.hex", "w");
        pixel_count = 0;
        total_outputs = 0;
        start = 1;             
        #50;                  
        producer_enable = 1; 
        wait(pixel_count >= 1024);
        #100;      
        $fclose(output_file);
        flush_fifo_and_reset();
        start = 0;
        #200;

        mode = 2'b10;  //Test convolution mode
        output_file = $fopen("output_conv.hex", "w");
        pixel_count = 0;
        total_outputs = 0;
        start = 1;             
        #50;                  
        producer_enable = 1; 
        wait(pixel_count >= 1024);
        #1000;      
        $fclose(output_file);
        flush_fifo_and_reset();
        start = 0;
        #200;

        mode = 2'b11;  //Test fourth mode which is not implemented and should not give any valid output
        total_outputs = 0;
        start = 1;             
        #50;                  
        producer_enable = 1; 
        #1000;     
        if (valid_out == 0) begin
            $display("Mode 1'b11 correctly produces no output");
        end else begin
            $display("ERROR: Mode 1'b11 is not valid!");
        end  
        flush_fifo_and_reset();
        start = 0;
        #200;


    end

endmodule
