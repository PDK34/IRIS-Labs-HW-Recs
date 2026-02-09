# Complete this file by writing the necessary startup code to properly initialize the system before transferring control to main. Do try to write it by yourself rather than copying it from uart_dv

.section .text
.globl _start

_start:
    la a0, _sidata     # Flash base address
    la a1, _sdata      # RAM base address
    la a2, _edata      # RAM end 

copy_data:
    bge a1, a2, zero_bss
    lw  t0, 0(a0)  # Copy data from flash to RAM
    sw  t0, 0(a1)
    addi a0, a0, 4
    addi a1, a1, 4
    j copy_data
zero_bss: # Zero the uninitialized variables in bss
    la a0, _sbss #Base address of bss
    la a1, _ebss #End address of bss

clear_bss:
    bge a0, a1, call_main
    sw  zero, 0(a0)
    addi a0, a0, 4
    j clear_bss

call_main:
    call main #The main function defined in firmware.c

hang:
    j hang #Infinite loop if main returns
