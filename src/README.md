# Applications

* `util.h`: utilities for sending a character over UART and reading CSRs

## Shell

A simple shell that can dump memory and display the cycle count, time, or number of retired instructions.

Modify `rtl/config.svh` such that this is defined
```verilog
`define SHELL_SIM
```

Running in simulation
```sh
cd src/shell
make
cd ../..
make -f SimMakefile
```

`sim/uart_terminal` can be used to interact with the system through UART. Details in [sim/README.md](../sim/README.md).

Example output
```sh
Starting
> c
Cycles: 36000948
> i
Instructions retired: 26669295
>
```

## Helloworld

Prints `Hello world!` over UART.

Modify `rtl/config.svh` such that this is defined
```verilog
`define HELLOWORLD_SIM
```

Running in simulation
```sh
cd src/helloworld
make
cd ../..
make -f SimMakefile
```

Output is printed to `mock_uart_output.txt`.

## CoreMark

Runs [CoreMark](https://github.com/eembc/coremark/tree/main).

Modify `rtl/config.svh` such that this is defined
```verilog
`define COREMARK_SIM
```

Modify `CC_FLAGS` in `src/coremark/Makefile` to select run type, iterations, and optimization level.

Running in simulation
```sh
cd src/coremark
make
cd ../..
make -f SimMakefile
```

Output is printed to `mock_uart_output.txt`.

### Results

* Simulated with verilator and run on an FPGA
* 10 MHz clock
* On-chip RAM of 32 KB

```
2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 22589627
Total time (secs): 22
Iterations/Sec   : 9
Iterations       : 200
Compiler version : GCC15.0.0 20241225 (experimental)
Compiler flags   : -DPERFORMANCE_RUN=1 -DITERATIONS=200 -O2
Memory location  : STACK
seedcrc          : 0xe9f5
[0]crclist       : 0xe714
[0]crcmatrix     : 0x1fd7
[0]crcstate      : 0x8e3a
[0]crcfinal      : 0x382f
Correct operation validated. See README.md for run and reporting rules.
```

## freertos

A simple FreeRTOS program that runs two non-returning tasks that print to UART at different delays.

Modify `rtl/config.svh` such that this is defined
```verilog
`define RTOS_EXAMPLE_SIM
```

Running in simulation
```sh
cd src/freertos
make
cd ../..
make -f SimMakefile
```

Output is printed to `mock_uart_output.txt`.

## Compilation requirements

* [RISC-V GNU toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain)
* An incomplete version is used to make the preceding applications, installed as follows

```
git clone --depth=1 git://gcc.gnu.org/git/gcc.git gcc
git clone --depth=1 git://sourceware.org/git/binutils-gdb.git
git clone --depth=1 git://sourceware.org/git/newlib-cygwin.git
mkdir combined
cd combined
ln -s ../newlib-cygwin/* .
ln -sf ../binutils-gdb/* .
ln -sf ../gcc/* .
mkdir build
cd build	
../configure --target=riscv32-unknown-elf --enable-languages=c --disable-shared --disable-threads --disable-gdb --disable-libssp --with-newlib --with-arch=rv32i --with-abi=ilp32 --prefix=/usr/local/share/gcc-riscv32-unknown-elf
make -j4
make
make install
export PATH=$PATH:/usr/local/share/gcc-riscv32-unknown-elf/bin/
riscv32-unknown-elf-gcc -v
```
Procedure modified from [DarkRISCV Development tools](https://github.com/darklife/darkriscv/blob/master/README.md#development-tools).

