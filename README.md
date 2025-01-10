# RISC-V CPU

A simple 32-bit RISC-V CPU core that supports the RV32I Base Integer Instruction Set and the "Zicsr" and "Zicntr" extensions.

The design is written in SystemVerilog. Design verification is done using UVM-SystemC, with Verilator as the simulator, CRAVE as the constrained randomization environment, and FC4SC as the functional coverage collector.

[Technical specification](./doc/technical_specification.md)

[Design verification document](./doc/dv_doc.md)

Other than DV for verifcation, applications have been successfully run on the CPU, with results printed through UART in simulation.

## Repository structure

* `doc/`: documentation, including the technical specification and design verification document
* `dv/cpu/`: design verification in C++
    * `sc_main.cpp`: 'top level' testbench
    * `cpu_util.*`: common utility
    * other: UVM-SystemC classes
* `rtl/`: design in SystemVerilog
    * `cpu.sv`: CPU design
    * `cpu.svh`: definitions
    * `config.svh`: configurations
    * `dual_port_ram.sv`: mock memory for smoke test
    * `uart*.sv`: UART modules with configurable baud rate, data bit size, stop bit, parity bit, and buffer size
    * `mock_uart_rx.sv`: mock UART receiver for recording app output during simulation
    * `address_decoder.sv`: decodes address to RAM or IO
    * `top.sv`: top level module
    * `bringup_top.sv`: simple top for smoke test
    * `sim_top.sv`: simulation top for running applications in simulation
* `src/`: applications
    * `helloworld/`: simple app that prints using UART
    * `coremark/`: CoreMark
    * [Details](./src/README.md)

## Simulation requirements

* [Verilator](https://verilator.org/guide/latest/index.html)
* [SystemC](https://github.com/accellera-official/systemc)
* [UVM-SystemC](https://www.accellera.org/downloads/drafts-review): UVM-SystemC Library 1.0-beta6 is used.
* [CRAVE](https://github.com/accellera-official/crave)
* [FC4SC](https://github.com/amiq-consulting/fc4sc)

Additional CRAVE requirements
* [Z3](https://github.com/Z3Prover/z3) version 4.6.0 is required.
* [CUDD](https://github.com/ivmai/cudd)
* [GLOG](https://github.com/google/glog)
* [BOOST](https://www.boost.org/)

`CMakeLists.txt` requires the following environment variables to be set
* `UVM_SYSTEMC_INCLUDE`
* `UVM_SYSTEMC_LIBDIR`
* `CRAVE_INCLUDE`
* `CRAVE_LIBDIR`
* `CRAVE_UVM_INCLUDE`
* `Z3_INCLUDE`
* `Z3_LIBDIR`
* `CUDD_INCLUDE`
* `CUDD_LIBDIR`
* `GLOG_INCLUDE`
* `GLOG_LIBDIR`
* `BOOST_INCLUDE`
* `BOOST_LIBDIR`
* `FC4SC_INCLUDE`
