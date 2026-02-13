RISCV_PREFIX = riscv64-unknown-elf-
CC = $(RISCV_PREFIX)gcc
OBJCOPY = $(RISCV_PREFIX)objcopy

CFLAGS = -march=rv32i -mabi=ilp32 -O2 -Wall -fno-builtin
LDFLAGS = -T sections.ld -nostdlib -nostartfiles -lgcc

XVLOG = xvlog
XELAB = xelab
XSIM = xsim

RTL = ../rvsoc.v ../rvsoc_wrapper.v ../picorv32.v ../simpleuart.v ../spimemio.v ../spiflash.v data_proc_wrapper.v data_proc.v

.PHONY: all firmware simulate clean

all: firmware simulate

firmware: firmware.hex

firmware.elf: firmware.c start.s sections.ld
	$(CC) $(CFLAGS) -o $@ start.s firmware.c $(LDFLAGS)

firmware.bin: firmware.elf
	$(OBJCOPY) -O binary $< $@

firmware.hex: firmware.bin
	python3 makehex.py $< $@

elaborate:
	$(XVLOG) --sv dataproc_tb.v $(RTL)
	$(XELAB) -debug typical dataproc_tb -s dataproc_tb_snapshot

simulate: firmware.hex elaborate
	$(XSIM) dataproc_tb_snapshot -runall

simulate_gui: firmware.hex elaborate
	$(XSIM) dataproc_tb_snapshot -gui


clean:
	@echo "Cleaning build files..."
	rm -f firmware.elf firmware.bin firmware.hex
	rm -rf xsim.dir .Xil
	rm -f *.wdb *.jou *.log *.pb *.str dfx_runtime.txt *.vcd *.wcfg 
