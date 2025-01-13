
RISCV_PREFIX ?= riscv32-unknown-elf-

RISCV_GCC ?= $(RISCV_PREFIX)gcc

RISCV_GCC_OPTS ?= \
				  -static \
				  -mcmodel=medany \
				  -fvisibility=hidden \
				  -nostartfiles \
				  -march=rv32i_zicsr \
				  -mabi=ilp32

				  # -nostdlib \

RISCV_OBJDUMP ?= \
				 $(RISCV_PREFIX)objdump \
				 --disassemble-all \
				 --disassemble-zeroes 

LINKER_SCRIPT ?= link.ld

BUILD_DIR ?= ./build

INCLUDE_DIRS ?= ../

SRCS ?= helloworld.c boot.s ../util.c

TARGET ?= helloworld

target: $(SRCS)
	mkdir -p $(BUILD_DIR)
	$(RISCV_GCC) $(SRCS) $(RISCV_GCC_OPTS) -I$(INCLUDE_DIRS) -T$(LINKER_SCRIPT) -o $(BUILD_DIR)/$(TARGET).o
	$(RISCV_OBJDUMP) $(BUILD_DIR)/$(TARGET).o > $(BUILD_DIR)/$(TARGET).dump
	$(RISCV_PREFIX)objcopy -O binary $(BUILD_DIR)/$(TARGET).o $(BUILD_DIR)/$(TARGET).copy
	hexdump -v -e '1/4 "%08x\n"' $(BUILD_DIR)/$(TARGET).copy > $(BUILD_DIR)/$(TARGET).mem
	cp $(BUILD_DIR)/$(TARGET).mem ../../

	# hexdump -v -e '1/1 "%02x\n"' $(BUILD_DIR)/$(TARGET).copy > $(BUILD_DIR)/$(TARGET).mem
	
all: target

clean:
	rm $(BUILD_DIR)/*
