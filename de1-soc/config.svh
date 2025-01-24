`ifndef __CONFIG__
`define __CONFIG__
`define RLEN 32
`define XLEN 32
`define IALIGN_B 4

`define RESET_PC 32'b0

`define CLK_FREQ 10000000

`define UART_BAUD_RATE 115200

`define ZMMUL
`define PRIV

`define MREG_PREFIX 8'hFF
`define MTIME_ADDR 32'hFFFF_FFF0
`define MTIME_H_ADDR 32'hFFFF_FFF4
`define MTIMECMP_ADDR 32'hFFFF_FF00
`define MTIMECMP_H_ADDR 32'hFFFF_FF04
`define MTIME_ADDR_8 8'hF0
`define MTIME_H_ADDR_8 8'hF4
`define MTIMECMP_ADDR_8 8'h00
`define MTIMECMP_H_ADDR_8 8'h04

`define QUARTUS

`endif
