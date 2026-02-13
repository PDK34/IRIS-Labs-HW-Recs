.section .text
.global _start

_start:
    #sp to top of RAM(128KB = 0x20000)
    li sp, 0x20000
    
    # Zero BSS section
    la a0, _sbss
    la a1, _ebss
zero_bss:
    bge a0, a1, call_main
    sw zero, 0(a0)
    addi a0, a0, 4
    j zero_bss

call_main:
    # Call main function
    call main

hang:
    # Infinite loop if main returns
    j hang
