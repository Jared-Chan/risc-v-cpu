# Applications

* `util.h`: utilities for sending a character over UART and reading CSRs

## Helloworld

Prints `Hello world!` over UART.

Modify `rtl/config.svh` such that these are defined
```verilog
`define SIM
`define MEM_INIT_FILE "helloworld.mem"
`define MEM_LEN_KB 4
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

Modify `rtl/config.svh` such that these are defined
```verilog
`define SIM
`define MEM_INIT_FILE "coremark.mem"
`define MEM_LEN_KB 32
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

* Simulated with verilator
* 10 MHz clock
* On-chip RAM of 32 KB

```
2K performance run parameters for coremark.
CoreMark Size    : 666
Total ticks      : 231633648
Total time (secs): 23
Iterations/Sec   : 8
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

