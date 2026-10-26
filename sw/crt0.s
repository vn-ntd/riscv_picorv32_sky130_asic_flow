/*
 * Bare-metal startup code for PicoRV32 (RV32I)
 */
.section .text.entry
.global _start
.type _start, @function

_start:
    /* 1. Initialize Stack Pointer to top of 64KB RAM */
    la sp, _stack_top

    /* 2. Zero-out the .bss section */
    la t0, _sbss
    la t1, _ebss
bss_loop:
    bge t0, t1, bss_done
    sw zero, 0(t0)
    addi t0, t0, 4
    j bss_loop
bss_done:

    /* 3. Call C main() */
    call main

    /* 4. Check main return code in a0 (0 = SUCCESS) */
    li t0, 0x10000000
    bnez a0, sim_fail

sim_pass:
    li t1, 1            /* 1 = SUCCESS status */
    sw t1, 0(t0)
    j halt

sim_fail:
    li t1, 2            /* 2 = FAIL status */
    sw t1, 0(t0)
    j halt

halt:
    j halt

.size _start, . - _start
