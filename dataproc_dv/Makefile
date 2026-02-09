# Makefile for RISC-V SoC with Data Processor
# Using Vivado for simulation

# RISC-V Toolchain
RISCV_PREFIX = riscv64-unknown-elf-
CC = $(RISCV_PREFIX)gcc
OBJCOPY = $(RISCV_PREFIX)objcopy
OBJDUMP = $(RISCV_PREFIX)objdump

# Compiler flags
CFLAGS = -march=rv32i -mabi=ilp32 -O2 -Wall
LDFLAGS = -T sections.ld -nostdlib -nostartfiles

# Vivado settings
VIVADO = vivado
VIVADO_MODE = batch
VIVADO_SCRIPT = run_sim.tcl

# Source files
FIRMWARE_SRC = firmware.c
STARTUP_ASM = start.s
LINKER_SCRIPT = sections.ld

# Verilog files
RTL_SRCS = ../rvsoc.v \
           ../rvsoc_wrapper.v \
           ../picorv32.v \
           ../simpleuart.v \
           ../spimemio.v \
           ../spiflash.v \
           data_proc_wrapper.v \
           data_proc.v \
           data_prod.v

TESTBENCH = dataproc_tb.v

# Output files
FIRMWARE_ELF = firmware.elf
FIRMWARE_HEX = firmware.hex
FIRMWARE_BIN = firmware.bin
FIRMWARE_MAP = firmware.map
FIRMWARE_DIS = firmware.dis

# Vivado project
VIVADO_PROJECT = rvsoc_sim
SIM_DIR = sim_output
WDB_FILE = $(SIM_DIR)/$(VIVADO_PROJECT).wdb

.PHONY: all firmware simulate clean help setup_sim

# Default target
all: firmware simulate

# Build firmware
firmware: $(FIRMWARE_HEX)

# Compile and link firmware
$(FIRMWARE_ELF): $(FIRMWARE_SRC) $(STARTUP_ASM) $(LINKER_SCRIPT)
	@echo "Compiling firmware for RISC-V..."
	$(CC) $(CFLAGS) $(LDFLAGS) -Wl,-Map=$(FIRMWARE_MAP) \
		-o $@ $(STARTUP_ASM) $(FIRMWARE_SRC)
	@echo "Created $@"

# Create binary
$(FIRMWARE_BIN): $(FIRMWARE_ELF)
	@echo "Creating binary file..."
	$(OBJCOPY) -O binary $< $@
	@echo "Created $@"

# Create hex file for SPI flash
$(FIRMWARE_HEX): $(FIRMWARE_BIN)
	@echo "Creating hex file for SPI flash..."
	python3 makehex.py $< 1048576 > $@
	@echo "Created $@"

# Create disassembly for debugging
$(FIRMWARE_DIS): $(FIRMWARE_ELF)
	@echo "Creating disassembly..."
	$(OBJDUMP) -D $< > $@
	@echo "Created $@"

# Create dummy image.hex if it doesn't exist
image.hex:
	@echo "Creating dummy image.hex..."
	@python3 -c "for i in range(256): print('00000000')" > $@
	@echo "Created $@"

# Setup Vivado simulation
setup_sim: $(VIVADO_SCRIPT)

$(VIVADO_SCRIPT): $(RTL_SRCS) $(TESTBENCH)
	@echo "Creating Vivado TCL script..."
	@echo "# Vivado simulation script" > $@
	@echo "create_project $(VIVADO_PROJECT) $(SIM_DIR) -part xc7a35tcpg236-1 -force" >> $@
	@echo "set_property simulator_language Verilog [current_project]" >> $@
	@for src in $(RTL_SRCS); do \
		echo "add_files $$src" >> $@; \
	done
	@echo "add_files -fileset sim_1 $(TESTBENCH)" >> $@
	@echo "set_property top dataproc_tb [get_filesets sim_1]" >> $@
	@echo "# Copy hex files to simulation directory" >> $@
	@echo "file copy -force ../firmware.hex [get_property DIRECTORY [current_project]]/firmware.hex" >> $@
	@echo "file copy -force ../image.hex [get_property DIRECTORY [current_project]]/image.hex" >> $@
	@echo "launch_simulation" >> $@
	@echo "run all" >> $@
	@echo "close_sim" >> $@
	@echo "close_project" >> $@
	@echo "exit" >> $@
	@echo "Created $@"

# Run Vivado simulation
simulate: setup_sim $(FIRMWARE_HEX) image.hex
	@echo "Running Vivado simulation..."
	$(VIVADO) -mode $(VIVADO_MODE) -source $(VIVADO_SCRIPT)
	@echo "Simulation complete!"
	@echo "Waveform database: $(WDB_FILE)"

# View waveform in Vivado GUI
view_wave:
	@echo "Opening waveform in Vivado..."
	$(VIVADO) $(WDB_FILE) &

# View disassembly
disasm: $(FIRMWARE_DIS)
	less $(FIRMWARE_DIS)

# Check firmware size
size: $(FIRMWARE_ELF)
	@echo "Firmware size:"
	@$(RISCV_PREFIX)size $(FIRMWARE_ELF)

# Clean build files
clean:
	@echo "Cleaning build files..."
	rm -f $(FIRMWARE_ELF) $(FIRMWARE_HEX) $(FIRMWARE_BIN)
	rm -f $(FIRMWARE_MAP) $(FIRMWARE_DIS)
	rm -f $(VIVADO_SCRIPT)
	rm -rf $(SIM_DIR)
	rm -rf .Xil
	rm -f *.jou *.log
	rm -f *.o
	@echo "Clean complete"

# Help
help:
	@echo "RISC-V SoC with Data Processor - Build System"
	@echo ""
	@echo "Targets:"
	@echo "  make all        - Build firmware and run simulation"
	@echo "  make firmware   - Build firmware only"
	@echo "  make simulate   - Run Vivado simulation"
	@echo "  make view_wave  - Open waveform in Vivado GUI"
	@echo "  make disasm     - View disassembly"
	@echo "  make size       - Show firmware size"
	@echo "  make clean      - Remove all build files"
	@echo "  make help       - Show this help"
	@echo ""
	@echo "Output files:"
	@echo "  firmware.hex    - Firmware for SPI flash"
	@echo "  firmware.elf    - RISC-V executable"
	@echo "  firmware.dis    - Disassembly listing"
	@echo "  sim_output/     - Vivado simulation files"
	@echo ""
