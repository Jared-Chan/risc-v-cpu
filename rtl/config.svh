`ifndef __CONFIG__
`define __CONFIG__
`define RLEN 32
`define XLEN 32
`define IALIGN_B 4

`define RESET_PC 32'b0

`define CLK_FREQ 10000000

`define UART_BAUD_RATE 115200

`define MTIME_ADDR 32'hFFFF_FFF0
`define MTIME_H_ADDR 32'hFFFF_FFF4
`define MTIMECMP_ADDR 32'hFFFF_FF00
`define MTIMECMP_H_ADDR 32'hFFFF_FF04

`define COREMARK_SIM
//`define HELLOWORLD_SIM
//`define SHELL_SIM
//`define RTOS_EXAMPLE_SIM

`ifdef COREMARK_SIM
    `define MEM_INIT_FILE "coremark.mem"
    `define MEM_LEN_KB 32
    `define VSIM
    `define ENV_FINISH
`elsif HELLOWORLD_SIM
    `define MEM_INIT_FILE "helloworld.mem"
    `define MEM_LEN_KB 4
    `define VSIM
    `define ENV_FINISH
`elsif SHELL_SIM
    `define MEM_INIT_FILE "shell.mem"
    `define MEM_LEN_KB 4
    `define VSIM
    `define ENV_FINISH
`elsif RTOS_EXAMPLE_SIM
    `define MEM_INIT_FILE "rtos_example.mem"
    `define MEM_LEN_KB 64
    `define VSIM
`endif

//`define DEBUG
//`define DEBUG_HEARTBEAT

`endif
