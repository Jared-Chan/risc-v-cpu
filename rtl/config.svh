`ifndef __CONFIG__
`define __CONFIG__
`define RLEN 32
`define XLEN 32
`define IALIGN_B 4

`define RESET_PC 32'b0

`define CSR_CYCLE 12'hC00
`define CSR_CYCLE_H 12'hC80
`define CSR_INSTRET 12'hC01
`define CSR_INSTRET_H 12'hC81

`define CLK_FREQ 10000000

`endif
