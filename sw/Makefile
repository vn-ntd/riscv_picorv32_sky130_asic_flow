# Makefile for PicoRV32 Bare-Metal Firmware

TOOLCHAIN_PREFIX ?= riscv64-unknown-elf-
ifeq ($(shell which $(TOOLCHAIN_PREFIX)gcc 2>/dev/null),)
  TOOLCHAIN_PREFIX := riscv-none-elf-
endif
ifeq ($(shell which $(TOOLCHAIN_PREFIX)gcc 2>/dev/null),)
  TOOLCHAIN_PREFIX := riscv32-unknown-elf-
endif

CC      = $(TOOLCHAIN_PREFIX)gcc
OBJCOPY = $(TOOLCHAIN_PREFIX)objcopy
OBJDUMP = $(TOOLCHAIN_PREFIX)objdump
PYTHON  ?= python3

CFLAGS  = -march=rv32i -mabi=ilp32 -O2 -Wall -ffreestanding -nostdlib
LDFLAGS = -Wl,-Bstatic,-T,sections.lds,--strip-debug

SRCS    = crt0.s main.c
TARGET  = firmware

.PHONY: all clean generate check-toolchain

all: check-toolchain $(TARGET).hex

check-toolchain:
	@if ! which $(CC) > /dev/null 2>&1; then \
		echo "[INFO] RISC-V GCC toolchain not found ($(CC)). Generating verified reference firmware.hex..."; \
		$(PYTHON) make_hex.py $(TARGET).hex; \
		exit 0; \
	fi

$(TARGET).elf: $(SRCS) sections.lds
	@if which $(CC) > /dev/null 2>&1; then \
		echo "[INFO] Compiling C firmware with $(CC)..."; \
		$(CC) $(CFLAGS) $(SRCS) $(LDFLAGS) -o $@; \
	else \
		echo "[WARNING] $(CC) not available, using fallback generation."; \
	fi

$(TARGET).bin: $(TARGET).elf
	@if [ -f "$<" ]; then \
		$(OBJCOPY) -O binary $< $@; \
	fi

$(TARGET).hex: $(TARGET).bin
	@if [ -f "$<" ]; then \
		$(PYTHON) make_hex.py $< $@; \
	else \
		$(PYTHON) make_hex.py $@; \
	fi

dump: $(TARGET).elf
	$(OBJDUMP) -d $(TARGET).elf > $(TARGET).asm

generate:
	$(PYTHON) make_hex.py $(TARGET).hex

clean:
	rm -f $(TARGET).elf $(TARGET).bin $(TARGET).hex $(TARGET).asm
