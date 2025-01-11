# Simulation tools

As opposed to design verification, these simulation tools support running and testing applications written for the CPU.

## UART Terminal

A tool that interactes with a verilator simulation through file IO, designed to be used in conjuction with `rtl/sim_top.sv`. 

![Simplified block diagram](./sim_top_uart_terminal.svg)

`sim_top` and `uart_terminal` both expect two files in the project root directory: `mock_uart_input.txt` and `mock_uart_output.txt`. `sim_top` reads from `mock_uart_input.txt` and sends every character to `top`, and writes every character received from `top` to `mock_uart_output.txt`. `uart_terminal` reads from `mock_uart_output.txt` and displays every character to the terminal, while taking in user input and writing it to `mock_uart_input.txt`.

If there is no activity from `sim_top` for one second, `uart_terminal` starts requesting user input. If more data is sent from `sim_top`, it will not be displayed until any user input is entered. 

Building:
```sh
cd sim
make
```

Usage example:
```sh
touch mock_uart_input.txt
touch mock_uart_output.txt
make -f SimMakefile
```
Note: if `mock_uart_input.txt` already contains data, `sim_top` will start sending it to `top`.

And on a separate terminal session
```sh
./sim/uart_terminal
```
When `uart_terminal` is ready for user input, `> ` will be printed on a new line.

