#!/usr/bin/env python3
"""
make_hex.py: Converts raw binary to 32-bit word hex format for Verilog $readmemh,
or generates a verified standalone RV32I firmware hex without needing a cross-compiler.
"""

import sys
import os

def bin_to_hex(bin_filename, hex_filename, word_count=16384):
    with open(bin_filename, "rb") as f:
        data = f.read()

    # Pad data to multiple of 4 bytes
    if len(data) % 4 != 0:
        data += b"\x00" * (4 - (len(data) % 4))

    words = []
    for i in range(0, len(data), 4):
        # Little-endian 32-bit word
        word = data[i] | (data[i+1] << 8) | (data[i+2] << 16) | (data[i+3] << 24)
        words.append(word)

    with open(hex_filename, "w") as f:
        for w in words:
            f.write(f"{w:08x}\n")

    print(f"[SUCCESS] Converted {len(words)} 32-bit words from {bin_filename} -> {hex_filename}")

def generate_default_hex(hex_filename):
    """
    Generates a full RV32I self-checking test sequence matching the core instruction verification suite:
    - Arithmetic (ADDI, ADD, SUB)
    - Bitwise Logic (AND, OR, XOR)
    - Shifts & Comparison (SLLI, SRLI, SLT)
    - Memory Access (SW, LW, BEQ)
    - Loop (BNE, JAL: Sum 1..5 = 15)
    - Completion Status write to 0x10000000 (1 = SUCCESS)
    """
    instructions = [
        0x00a00093, # 0x00: addi x1, x0, 10
        0x01400113, # 0x04: addi x2, x0, 20
        0x002081b3, # 0x08: add  x3, x1, x2 (x3 = 30)
        0x40118233, # 0x0c: sub  x4, x3, x1 (x4 = 20)
        0x08221463, # 0x10: bne  x4, x2, FAIL (0x98)
        0x00f00293, # 0x14: addi x5, x0, 15 (0x0F)
        0x03300313, # 0x18: addi x6, x0, 51 (0x33)
        0x0062f3b3, # 0x1c: and  x7, x5, x6 (x7 = 3)
        0x00300413, # 0x20: addi x8, x0, 3
        0x06839a63, # 0x24: bne  x7, x8, FAIL (0x98)
        0x0062e4b3, # 0x28: or   x9, x5, x6 (x9 = 63)
        0x03f00513, # 0x2c: addi x10, x0, 63
        0x06a49463, # 0x30: bne  x9, x10, FAIL (0x98)
        0x0062c5b3, # 0x34: xor  x11, x5, x6 (x11 = 60)
        0x03c00613, # 0x38: addi x12, x0, 60
        0x04c59e63, # 0x3c: bne  x11, x12, FAIL (0x98)
        0x00229693, # 0x40: slli x13, x5, 2 (15 << 2 = 60)
        0x04c69a63, # 0x44: bne  x13, x12, FAIL (0x98)
        0x0026d713, # 0x48: srli x14, x13, 2 (60 >> 2 = 15)
        0x04571663, # 0x4c: bne  x14, x5, FAIL (0x98)
        0x0020a7b3, # 0x50: slt  x15, x1, x2 (10 < 20 -> 1)
        0x00100813, # 0x54: addi x16, x0, 1
        0x05079063, # 0x58: bne  x15, x16, FAIL (0x98)
        0x04302023, # 0x5c: sw   x3, 64(x0) (store 30)
        0x04002883, # 0x60: lw   x17, 64(x0) (load 30)
        0x00388463, # 0x64: beq  x17, x3, 8 (offset +8 -> 0x6c)
        0x0300006f, # 0x68: j FAIL (0x98)
        0x00500913, # 0x6c: addi x18, x0, 5 (counter)
        0x00000993, # 0x70: addi x19, x0, 0 (sum)
        0x012989b3, # 0x74: add  x19, x19, x18
        0xfff90913, # 0x78: addi x18, x18, -1
        0xfe091ce3, # 0x7c: bne  x18, x0, -8 (-> 0x74)
        0x00f00a13, # 0x80: addi x20, x0, 15
        0x01499a63, # 0x84: bne  x19, x20, FAIL (0x98)
        # SUCCESS Handler (0x88)
        0x10000ab7, # 0x88: lui  x21, 0x10000
        0x00100b13, # 0x8c: addi x22, x0, 1
        0x016aa023, # 0x90: sw   x22, 0(x21) -> Status PASS (1)
        0x0000006f, # 0x94: j HALT
        # FAIL Handler (0x98)
        0x10000ab7, # 0x98: lui  x21, 0x10000
        0x00200b13, # 0x9c: addi x22, x0, 2
        0x016aa023, # 0xa0: sw   x22, 0(x21) -> Status FAIL (2)
        0x0000006f, # 0xa4: j FAIL_HALT
    ]

    with open(hex_filename, "w") as f:
        for insn in instructions:
            f.write(f"{insn:08x}\n")

    print(f"[SUCCESS] Generated verified RV32I verification sequence ({len(instructions)} words) -> {hex_filename}")

if __name__ == "__main__":
    if len(sys.argv) == 3:
        bin_to_hex(sys.argv[1], sys.argv[2])
    elif len(sys.argv) == 2:
        generate_default_hex(sys.argv[1])
    else:
        out_file = os.path.join(os.path.dirname(__file__), "firmware.hex")
        generate_default_hex(out_file)
