
RISCV_PREFIX ?= riscv32-unknown-elf-

RISCV_GCC ?= $(RISCV_PREFIX)gcc

RISCV_GCC_OPTS ?= \
				  -static \
				  -mcmodel=medany \
				  -fvisibility=hidden \
				  -ffreestanding \
				  -march=rv32i_zicsr \
				  -mabi=ilp32  \

				  # -nostdlib \
				  # -nostartfiles \

				  # -D__RISCV__ \
				  # -lm \
				  # -L/usr/local/share/gcc-riscv32-unknown-elf/lib/gcc/riscv32-unknown-elf/15.0.0/

RISCV_OBJDUMP ?= \
				 $(RISCV_PREFIX)objdump \
				 --disassemble-all \
				 --disassemble-zeroes 

LINKER_SCRIPT ?= coremark.ld

BUILD_DIR ?= ./build

SRCS = ./core_main.c ./core_matrix.c ./core_list_join.c ./core_state.c ./core_util.c core_portme.c ./ee_printf.c ./boot.s

HEADERS = ./coremark.h ./core_portme.h ../util.h
INCLUDE_DIRS = -I./ -I../

CC_FLAGS = -DFLAGS_STR=\""-DPERFORMANCE_RUN=1 -DITERATIONS=25 -O2"\" 
CC_FLAGS += -DPERFORMANCE_RUN=1 -DITERATIONS=25 -O2

target: $(SRCS)
	mkdir -p $(BUILD_DIR)
	$(RISCV_GCC) $(INCLUDE_DIRS) $(SRCS) $(RISCV_GCC_OPTS) $(CC_FLAGS) -T$(LINKER_SCRIPT) -o $(BUILD_DIR)/coremark.o
	$(RISCV_OBJDUMP) $(BUILD_DIR)/coremark.o > $(BUILD_DIR)/coremark.dump
	$(RISCV_PREFIX)objcopy -O binary $(BUILD_DIR)/coremark.o $(BUILD_DIR)/coremark.copy
	hexdump -v -e '1/1 "%02x\n"' $(BUILD_DIR)/coremark.copy > $(BUILD_DIR)/coremark.mem
	hexdump -v -e '1/4 "%08x\n"' $(BUILD_DIR)/coremark.copy > $(BUILD_DIR)/coremark.memx4
	cp $(BUILD_DIR)/coremark.mem ../../
	

# cp $(BUILD_DIR)/coremark.mem ../
	

.PHONY: all

all: target


clean:
	rm $(BUILD_DIR)/*
