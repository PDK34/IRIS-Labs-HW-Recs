`timescale 1ns/1ps

module dataproc_tb;
	reg clk = 0;
	always #5 clk = ~clk;

	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;

	always @(posedge clk) begin
		if (reset_cnt < 63)
			reset_cnt <= reset_cnt + 1;
	end

	wire ser_rx = 1'b1;
	wire ser_tx;

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;
	wire flash_io2;
	wire flash_io3;

	initial begin
		$dumpfile("dataproc_tb.vcd");
		$dumpvars(0, dataproc_tb);
		
		$display("\nSimulation Started");
		
		$readmemh("firmware.hex", uut.soc.memory.mem);

		$readmemh("image.hex", spiflash.memory, 32'h100000);
		
		@(posedge resetn);
		$display("[%0t]Reset released\n", $time);
		
		#50000000;
		$display("\n\n--Simulation Complete--");
		$finish;
	end
	
	//UART Monitor
	always @(posedge clk) begin
		if (uut.soc.simpleuart.reg_dat_we) begin
			$write("%c", uut.soc.simpleuart.reg_dat_di[7:0]);
			$fflush();
			//Wait for the write signal to drop before looking for the next one
			wait(!uut.soc.simpleuart.reg_dat_we); 
		end
	end

	rvsoc_wrapper #(
		.MEM_WORDS(32768)
	) uut (
		.clk      (clk),
		.resetn   (resetn),
		.ser_rx   (ser_rx),
		.ser_tx   (ser_tx),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.flash_io2(flash_io2),
		.flash_io3(flash_io3)
	);

	spiflash spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(flash_io2),
		.io3(flash_io3)
	);
endmodule
