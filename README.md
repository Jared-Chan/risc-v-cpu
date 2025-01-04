# RISC-V CPU

A simple 32-bit RISC-V CPU core that supports the RV32I Base Integer Instruction Set and the "Zicsr" and "Zicntr" extensions.

[Technical specification](./doc/technical_specification.md)

[Design verification document](./doc/dv_doc.md)

## Repository structure

* `doc/`: documentation, including the technical specification and design verification document
* `dv/`: design verification in C++
    * `sc_main.cpp`: 'top level' testbench
    * `cpu_util.*`: common utility
    * other: UVM-SystemC classes
* `rtl/`: design in SystemVerilog
    * `cpu.sv`: design
    * `cpu.svh`: definitions
    * `dual_port_ram.sv`: mock memory for smoke test
    * `top.sv`: simple top for smoke test

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
