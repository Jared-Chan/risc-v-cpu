
RISCV_PREFIX ?= riscv32-unknown-elf-

RISCV_GCC ?= $(RISCV_PREFIX)gcc

RISCV_GCC_OPTS ?= \
				  -static \
				  -mcmodel=medany \
				  -fvisibility=hidden \
				  -nostartfiles \
				  -march=rv32i_zicsr_zmmul \
				  -mabi=ilp32

RISCV_OBJDUMP ?= \
				 $(RISCV_PREFIX)objdump \
				 --disassemble-all \
				 --disassemble-zeroes 

LINKER_SCRIPT ?= link.ld

BUILD_DIR ?= ./build

INCLUDE_UTIL_DIR ?= ..
INCLUDE_DIR ?= .

FREERTOS_KERNEL_DIR ?= ./FreeRTOS-Kernel
FREERTOS_INCLUDE_DIR ?= $(FREERTOS_KERNEL_DIR)/include
FREERTOS_PORT_INCLUDE_DIR ?= $(FREERTOS_KERNEL_DIR)/portable/GCC/RISC-V

INCLUDE_DIRS ?= \
				-I$(INCLUDE_DIR) \
				-I$(INCLUDE_UTIL_DIR) \
				-I$(FREERTOS_INCLUDE_DIR) \
				-I$(FREERTOS_PORT_INCLUDE_DIR)

SRCS ?= \
		main.c \
		external_interrupt_handler.c \
		boot.S \
		../util.c \
		$(FREERTOS_KERNEL_DIR)/*.c \
		$(FREERTOS_PORT_INCLUDE_DIR)/port.c \
		portASM.S 

		#$(FREERTOS_KERNEL_DIR)/portable/MemMang/heap_4.c \

TARGET ?= rtos_example

FREERTOS_DEF ?= \
				-DportasmHANDLE_INTERRUPT=external_interrupt_handler \
				-D__riscv_xlen=32

FREERTOS_CONFIG_HEADERS ?= \
						   -include $(INCLUDE_DIR)/FreeRTOSConfig.h \
						   -imacros $(INCLUDE_DIR)/freertos_risc_v_chip_specific_extensions.h \
						   -imacros $(FREERTOS_PORT_INCLUDE_DIR)/portContext.h


all: target

target: $(SRCS)
	$(RISCV_GCC) $(FREERTOS_DEF) $(FREERTOS_CONFIG_HEADERS) $(SRCS) $(RISCV_GCC_OPTS) $(INCLUDE_DIRS) -T$(LINKER_SCRIPT) -o $(BUILD_DIR)/$(TARGET).o
	$(RISCV_OBJDUMP) $(BUILD_DIR)/$(TARGET).o > $(BUILD_DIR)/$(TARGET).dump
	$(RISCV_PREFIX)objcopy -O binary $(BUILD_DIR)/$(TARGET).o $(BUILD_DIR)/$(TARGET).copy
	hexdump -v -e '1/4 "%08x\n"' $(BUILD_DIR)/$(TARGET).copy > $(BUILD_DIR)/$(TARGET).mem
	cp $(BUILD_DIR)/$(TARGET).mem ../../
	
clean:
	rm $(BUILD_DIR)/*
