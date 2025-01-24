# CPU Technical Specification

<!--Document based on https://github.com/lowRISC/opentitan/blob/master/hw/ip/otbn/README.md-->

# Overview

CPU is a 32-bit RISC-V CPU core that supports the RV32I Base Integer Instruction Set and the "Zicntr" extension and partially supports the "Zicsr" extension and machine-level privileged ISA.

## Features

* 2-stage pipeline
* Cycle, time, and retired instruction counters
* M-mode timer interrupts and exceptions

<!--## Description-->
<!---->
<!--CPU is a simple processor that is compliant with the RV32I Base Integer Instruction Set and the "Zicsr" and "Zicntr" extensions.-->
<!---->
# Instruction Set

The RV32I Base Integer Instruction Set and the "Zicsr" and "Zicntr" extensions. The following CSRs are supported 
* `CYCLE`
* `INSTRET`
* `TIME`
* `MISA`
* `MSTATUS`
* `MTVEC`
* `MIE`
* `MIP`
* `MSCRATCH`
* `MEPC`
* `MCAUSE`
* `MTVAL`

## Processor State

### General Purpose Registers (GPRs)

CPU has 32 General Purpose Registers (GPRs), each of which is 32b wide.
The GPRs are defined in line with RV32I.

<table>
  <tr>
    <td><code>x0</code></td>
    <td>Zero register. Reads as 0; writes are ignored.</td>
  </tr>
  <tr>
    <td><code>x1</code> ... <code>x31</code></td>
    <td>General purpose registers</td>
  </tr>
</table>

### Program Counter (PC)

CPU has one 32b wide program counter. CPU assumes `IALIGN=32`.

<table>
  <tr>
    <td><code>pc</code></td>
    <td>Program counter. Initialized to <code>0</code> upon reset; incremented by 4 after each instruction retirement.</td>
  </tr>
</table>


### Control and Status Registers (CSRs)

Control and Status Registers (CSRs) are 32b wide registers for special purposes.
The access to CSRs are defined in line with the "Zicsr" extension and privileged ISA.

<table>
  <thead>
    <tr>
      <th>Number</th>
      <th>Access</th>
      <th>Name</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>0x300</td>
      <td>WR</td>
      <td>MSTATUS</td>
      <td>
      Operating state of the hart.
      </td>
    </tr>
    <tr>
      <td>0x301</td>
      <td>WARL</td>
      <td>MISA</td>
      <td>
      Supported ISA.
      </td>
    </tr>
    <tr>
      <td>0x304</td>
      <td>WR</td>
      <td>MIE</td>
      <td>
      Interrupt enable.
      </td>
    </tr>
    <tr>
      <td>0x305</td>
      <td>WARL</td>
      <td>MTVEC</td>
      <td>
      Trap vector configuration.
      </td>
    </tr>
    <tr>
      <td>0x310</td>
      <td>WR</td>
      <td>MSTATUS_H</td>
      <td>
      Operating state of the hart.
      </td>
    </tr>
    <tr>
      <td>0x340</td>
      <td>WR</td>
      <td>MSCRATCH</td>
      <td>
      Scratch.
      </td>
    </tr>
    <tr>
      <td>0x341</td>
      <td>WR</td>
      <td>MEPC</td>
      <td>
      Machine exception program counter.
      </td>
    </tr>
    <tr>
      <td>0x342</td>
      <td>WR</td>
      <td>MCAUSE</td>
      <td>
      Trap cause.
      </td>
    </tr>
    <tr>
      <td>0x343</td>
      <td>WR</td>
      <td>MTVAL</td>
      <td>
      Exception-specific information.
      </td>
    </tr>
    <tr>
      <td>0x344</td>
      <td>WR</td>
      <td>MIP</td>
      <td>
      Interrupt pending.
      </td>
    </tr>
    <tr>
      <td>0xC00</td>
      <td>R</td>
      <td>CYCLE</td>
      <td>
      The lower 32 bits of the amount of cycles since an arbitrary start time in the past.
      </td>
    </tr>
    <tr>
      <td>0xC01</td>
      <td>R</td>
      <td>TIME</td>
      <td>
      The lower 32 bits of the time passed since an arbitrary start time in the past. The unit is microseconds.
      </td>
    </tr>
    <tr>
      <td>0xC02</td>
      <td>R</td>
      <td>INSTRET</td>
      <td>
      The lower 32 bits of the amount of instructions retired since an arbitrary start time in the past.
      </td>
    </tr>
    <tr>
      <td>0xC80</td>
      <td>R</td>
      <td>CYCLE_H</td>
      <td>
      The upper 32 bits of the amount of cycles since an arbitrary start time in the past.
      </td>
    </tr>
    <tr>
      <td>0xC81</td>
      <td>R</td>
      <td>TIME_H</td>
      <td>
      The upper 32 bits of the time passed since an arbitrary start time in the past.
      </td>
    </tr>
    <tr>
      <td>0xC82</td>
      <td>R</td>
      <td>INSTRET_H</td>
      <td>
      The upper 32 bits of the amount of instructions retired since an arbitrary start time in the past.
      </td>
    </tr>
  </tbody>
</table>

### Memory-mapped Registers

<table>
  <thead>
    <tr>
      <th>Address</th>
      <th>Name</th>
      <th>Width</th>
      <th>Access</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>0xFFFF_FF00</td>
      <td>MTIMECMP</td>
      <td>32</td>
      <td>WR</td>
      <td>
      A machine timer interrupt becomes pending when MTIME > MTIMECMP.
      </td>
    </tr>
    <tr>
      <td>0xFFFF_FF04</td>
      <td>MTIMECMP_H</td>
      <td>32</td>
      <td>WR</td>
      <td>
      A machine timer interrupt becomes pending when MTIME > MTIMECMP.
      </td>
    </tr>
    <tr>
      <td>0xFFFF_FFF0</td>
      <td>MTIME</td>
      <td>32</td>
      <td>WR</td>
      <td>
      The lower 32 bits of the time passed since an arbitrary start time in the past. The unit is microseconds.
      </td>
    </tr>
    <tr>
      <td>0xFFFF_FFF4</td>
      <td>MTIME_H</td>
      <td>32</td>
      <td>WR</td>
      <td>
      The upper 32 bits of the time passed since an arbitrary start time in the past.
      </td>
    </tr>
  </tbody>
</table>

## Interfaces

<table>
  <thead>
    <tr>
      <th>Signal</th>
      <th>Width</th>
      <th>Dir</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>clk</code></td>
      <td>1</td>
      <td>in</td>
      <td>
      Clock.
      </td>
    </tr>
    <tr>
      <td><code>rst_n</code></td>
      <td>1</td>
      <td>in</td>
      <td>
      Active-low asynchronous reset.
      </td>
    </tr>
    <tr>
      <td><code>iaddr_o</code></td>
      <td>30</td>
      <td>out</td>
      <td>
      Address to the instruction memory. First address after reset is <code>0</code>. Assumes memory is word-aligned.
      </td>
    </tr>
    <tr>
      <td><code>idata_i</code></td>
      <td>32</td>
      <td>in</td>
      <td>
      Instruction data from instruction memory. Assumed valid one cycle after <code>iaddr_o</code> is set.
      </td>
    </tr>
    <tr>
      <td><code>addr_o</code></td>
      <td>30</td>
      <td>out</td>
      <td>
      Address to the data memory. Assumes memory is word-aligned.
      </td>
    </tr>
    <tr>
      <td><code>data_i</code></td>
      <td>32</td>
      <td>in</td>
      <td>
      Data from data memory. Assumed valid one cycle after <code>addr_o</code> is set.
      </td>
    </tr>
    <tr>
      <td><code>wdata_o</code></td>
      <td>32</td>
      <td>out</td>
      <td>
      Data to be written to data memory. Assumed written one cycle after this and <code>wr_o</code> are set.
      </td>
    </tr>
    <tr>
      <td><code>wr_o</code></td>
      <td>1</td>
      <td>out</td>
      <td>
      Active-high write-enable to data memory.
      </td>
    </tr>
    <tr>
      <td><code>data_addr_strobe_o</code></td>
      <td>1</td>
      <td>out</td>
      <td>
      Active-high address strobe
      </td>
    </tr>
    <tr>
      <td><code>byte_en_o</code></td>
      <td>4</td>
      <td>out</td>
      <td>
      Active-high byte enable to data memory.
      </td>
    </tr>
    <tr>
      <td><code>ibyte_en_o</code></td>
      <td>4</td>
      <td>out</td>
      <td>
      Active-high byte enable to instruction memory.
      </td>
    </tr>
    <tr>
      <td><code>clk_mul</code></td>
      <td>1</td>
      <td>in</td>
      <td>
      Clock for multiplier. Its frequency should be at least that of clk.
      </td>
    </tr>
  </tbody>
</table>
