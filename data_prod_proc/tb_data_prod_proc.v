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

    wire [7:0] pixel;
    wire valid;
    wire ready;


	/* Write your tb logic for your combined design here */




	/*---------------------------------------------------*/

	data_proc data_processing (
        .clk(clk),
        .rstn(resetn),

        // Fill the rest

	);

	data_prod data_producer (
        .sensor_clk(sensor_clk),
        .rstn(sensor_resetn),
        .ready(ready),
        .pixel(pixel),
        .valid(valid)
	);


endmodule
