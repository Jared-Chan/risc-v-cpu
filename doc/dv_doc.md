# CPU DV document

<!--Document based on https://github.com/lowRISC/opentitan/blob/master/hw/dv/doc/dv_doc_template.md-->

## Goals
* **DV**
  * Verify the core's support of the RV32I Base Integer Instruction Set with the "Zicsr" and "Zicntr" extensions by running dynamic simulations with a UVM-SystemC based testbench that uses CRAVE for constraint randomization and FC4SC for coverage collection
  * Develop and run all tests based on the [testplan](#testplan) below towards closing code and functional coverage on the core

## Current status

Summary
* functional coverage: 95.43%
* `FENCE`, `ECALL`, and `EBREAK` aren't implemented

Details: [coverage results](./coverage_results.xml)

## Design features
<!-- TODO: uncomment link to the spec below -->
For detailed information on CPU design features, please see the [CPU technical specification](./technical_specification.md).

## Testbench architecture

### Block diagram
![Block diagram](./cpu_tb.svg)

### Top level testbench
Top level testbench is located at `dv/sc_main.cpp`. It instantiates the CPU DUT module `rtl/cpu.sv` that is verilated to `Vcpu.h`.
It instantiates the following interface and sets its handle into `uvm_config_db`:
* [CPU interface](../dv/cpu_if.hpp)

<!--### Common DV utility components-->
<!--No common DV utility-->

### Compile-time configurations

Configurations are made in `dv/sc_main.cpp`, they're
* base test sequence length
* UVM verbosity
* CRAVE config file
* test name
* coverage results file

Currently, the testbench doesn't support commandline arguments.

### Global types & methods
Many common types and utility methods are declared in `dv/cpu_utility.hpp` under the namespace `cpu_util`, including
```cpp
enum class Opcode {...};
enum class F3 {...};
enum class F7 {...};
void make_instruction(...);
void print_instruction(...);
void decode_idata(...);
```
### cpu_agent
CPU testbench instantiates `cpu_env`, which instantiates `cpu_agent`.
`cpu_agent` provides the ability to drive and monitor traffic at the CPU interface.

<!--### UVM RAL Model-->

### Reference models
CPU testbench doesn't use reference models.

### Stimulus strategy
#### Test sequences
The only sequence is defined in `cpu_sequence.hpp`.
It contains a `length` member variable configured in `dv/sc_main.cpp`, and a `cpu_scenario_item`. It uses the `cpu_scenario_item` to repeatedly generate test instructions in the form of `cpu_seq_item`s, which are used as both requests and responses to the DUT.

#### Functional coverage
`dv/cpu_covergroup.hpp` defines the coverpoints that cover 
* opcodes
* functions of opcodes
* source and destination registers
* address and data ranges
* data writing and reading
* reset

### Checking strategy

#### CPU scenario item
`dv/cpu_scenario_item.hpp` defines a `uvm_randomized_sequence_item` that provides three functions for `cpu_sequence` to run tests:
* `randomize()`
    * an inherited function for randomization
* `generate_instructions(...)`
    * based on randomized fields, generates
        * 6-9 instructions 
        * expected instruction addresses
        * expected read and write addresses and data
* `has_next_instruction(...)`
    * signifies whether the currect randomized test should continue
* `get_next_instruction(...)`
    * provides the next input to DUT
    * checks the previous DUT output

The 6-9 generated instructions are self-contained, meaning they contain the necessary setup and result-checking instructions. In brief, the set of instructions are
* jump to a new address
* set source registers, and CSR registers if needed
* run a random instruction
* if needed, store results in a specific address for checking

Although there is an overhead in setup and result-checking, no reference models or memory models are needed.

`dv/cpu_scenario_item.hpp` also contains extensive constraints, allowing for meaningful and legal operations. 

#### Scoreboard
The `cpu_scoreboard` defined in `dv/cpu_scoreboard.hpp` is only used to check reset behavior, since most checking is done in `dv/cpu_scenario_item.hpp`.
It contains the following analysis port
* `cpu_item_export`
    * receives all transactions at the CPU interface
    * when `rst_n` is active, checks `iaddr`

#### Assertions
Assertions aren't used.

## Building and running tests

The simulator used is verilator.

The build system is cmake, which verilates the RTL CPU in SystemVerilog, compiles the DV testbench in C++, and links the two with the required libraries like UVM-SystemC, CRAVE, and FC4SC. In `dv/sc_main.cpp`, `length` is set to 1000000 to get a functional coverage of 99.65%.

```console
$ cd build
$ cmake ..
$ make
$ ./sim
```

## Testplan

All instructions in the RV32I base standard and the "Zicsr" and "Zicntr" extensions should be supported.

### Tests
Test: `base_test`
* `dv/test.hpp` defines a `base_test` class that instantiates `cpu_sequence` which uses `cpu_scenario_item` to generate all supported instructions and expected responses.

### Covergroups

#### `cpu_covergroup`
Covers
* opcodes
* functions of opcodes
* source and destination registers
* address and data ranges
* data writing and reading
* reset
