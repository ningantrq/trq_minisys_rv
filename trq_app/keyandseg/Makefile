RISCV_PREFIX ?= riscv32-unknown-elf-
RISCV_GCC ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS ?= -ffreestanding -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -march=rv32im -mabi=ilp32
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump --disassemble-all
RISCV_OBJCOPY ?= $(RISCV_PREFIX)objcopy

default: all

all: main.elf main.dump main.bin main.coe

main.elf: main.c keyboard.c seg.c
	$(RISCV_GCC) $(RISCV_GCC_OPTS) -Tlink.ld -I. $^ -o $@

main.dump: main.elf
	$(RISCV_OBJDUMP) -d $< > $@

main.bin: main.elf
	$(RISCV_OBJCOPY) -O binary $< $@

main.coe: main.bin
	python3 ../../difftest/script/bin_to_coe.py --input-file $< --output-file $@

clean:
	rm -rf *.elf *.bin *.coe *.dump
