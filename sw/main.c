/*
 * PicoRV32 Bare-Metal Verification Firmware in C (RV32I)
 */

#include <stdint.h>

#define STATUS_ADDR ((volatile uint32_t *)0x10000000)

/* Simple software shift-and-add multiply to stay strictly RV32I without libgcc */
static uint32_t soft_mul(uint32_t a, uint32_t b) {
    uint32_t res = 0;
    while (b > 0) {
        if (b & 1)
            res += a;
        a <<= 1;
        b >>= 1;
    }
    return res;
}

static int test_arithmetic(void) {
    volatile int a = 10;
    volatile int b = 25;
    volatile int c = a + b;
    if (c != 35) return -1;

    volatile int d = b - a;
    if (d != 15) return -2;

    /* Bitwise logic */
    volatile uint32_t x = 0x0F0F0F0F;
    volatile uint32_t y = 0x33333333;
    if ((x & y) != 0x03030303) return -3;
    if ((x | y) != 0x3F3F3F3F) return -4;
    if ((x ^ y) != 0x3C3C3C3C) return -5;

    /* Shifts & Comparisons */
    volatile uint32_t s = 15;
    if ((s << 2) != 60) return -6;
    if ((s >> 1) != 7)  return -7;
    if (a >= b)         return -8;

    /* Soft multiplication */
    if (soft_mul(7, 8) != 56) return -9;

    return 0;
}

static volatile uint32_t test_buffer[16];

static int test_memory(void) {
    for (int i = 0; i < 16; i++) {
        test_buffer[i] = (uint32_t)(i * 100 + 7);
    }

    for (int i = 0; i < 16; i++) {
        if (test_buffer[i] != (uint32_t)(i * 100 + 7)) {
            return -1;
        }
    }
    return 0;
}

static int test_loop(void) {
    int sum = 0;
    for (int i = 1; i <= 10; i++) {
        sum += i;
    }
    /* Sum 1..10 = 55 */
    if (sum != 55) return -1;
    return 0;
}

int main(void) {
    if (test_arithmetic() != 0) return 1;
    if (test_memory() != 0)     return 2;
    if (test_loop() != 0)       return 3;

    /* Write status register explicitly (also verified in crt0.s) */
    *STATUS_ADDR = 1;

    return 0;
}
