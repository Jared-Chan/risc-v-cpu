# Running DV Simulations

## Simulation requirements

* [Verilator](https://verilator.org/guide/latest/index.html)

### Additional requirements for building

* [SystemC](https://github.com/accellera-official/systemc)
* [UVM-SystemC](https://www.accellera.org/downloads/drafts-review): UVM-SystemC Library 1.0-beta6 is used.
* [CRAVE](https://github.com/accellera-official/crave)
* [FC4SC](https://github.com/amiq-consulting/fc4sc)

Additional CRAVE requirements
* [Z3](https://github.com/Z3Prover/z3) version 4.6.0 is required.
* [CUDD](https://github.com/ivmai/cudd)
* [GLOG](https://github.com/google/glog)
* [BOOST](https://www.boost.org/)

`$REPO_ROOT/CMakeLists.txt` requires the following environment variables to be set
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

## Building and running tests

The build system is cmake, which verilates the RTL CPU in SystemVerilog, compiles the DV testbench in C++, and links the two with the required libraries like UVM-SystemC, CRAVE, and FC4SC. In `dv/cpu/sc_main.cpp`, `length` is set to 100000 to get a functional coverage of >95%.

In `rtl/config.svh`, the following should be defined
```verilog
`define DV
```

From the root of the repository,
```console
$ cd build
$ cmake ..
$ make
$ ./cpu_sim
```

