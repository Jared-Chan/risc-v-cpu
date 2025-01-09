
RISCV_PREFIX ?= riscv32-unknown-elf-

RISCV_GCC ?= $(RISCV_PREFIX)gcc

RISCV_GCC_OPTS ?= \
				  -static \
				  -mcmodel=medany \
				  -fvisibility=hidden \
				  -nostdlib \
				  -nostartfiles \
				  -march=rv32i \
				  -mabi=ilp32

RISCV_OBJDUMP ?= \
				 $(RISCV_PREFIX)objdump \
				 --disassemble-all \
				 --disassemble-zeroes 

LINKER_SCRIPT ?= link.ld

BUILD_DIR ?= ./build


target: helloworld.c
	mkdir -p $(BUILD_DIR)
	$(RISCV_GCC) helloworld.c boot.s $(RISCV_GCC_OPTS) -T$(LINKER_SCRIPT) -o $(BUILD_DIR)/helloworld.o
	$(RISCV_OBJDUMP) $(BUILD_DIR)/helloworld.o > $(BUILD_DIR)/helloworld.dump
	$(RISCV_PREFIX)objcopy -O binary $(BUILD_DIR)/helloworld.o $(BUILD_DIR)/helloworld.copy
	hexdump -v -e '1/1 "%02x\n"' $(BUILD_DIR)/helloworld.copy > $(BUILD_DIR)/helloworld.mem
	hexdump -v -e '1/4 "%08x\n"' $(BUILD_DIR)/helloworld.copy > $(BUILD_DIR)/helloworld.memx4
	cp $(BUILD_DIR)/helloworld.mem ../
	
all: target


clean:
	rm helloworld.o helloworld.dump
