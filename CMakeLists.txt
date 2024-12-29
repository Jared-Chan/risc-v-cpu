cmake_minimum_required(VERSION 3.27)
set (CMAKE_CXX_STANDARD 17)

project(riscv-cpu)
find_package(verilator)

include_directories($ENV{UVM_SYSTEMC_INCLUDE})
link_directories($ENV{UVM_SYSTEMC_LIBDIR})

# Design
add_library(dut)
verilate(dut
SYSTEMC
SOURCES rtl/cpu.sv)
verilator_link_systemc(dut)

# Testbench
add_executable(sim
dv/sc_main.cpp
dv/test.hpp
dv/cpu_agent.hpp
dv/cpu_driver.hpp
dv/cpu_env.hpp
dv/cpu_if.hpp
dv/cpu_monitor.hpp
dv/cpu_scoreboard.hpp
dv/cpu_seq_item.hpp
dv/cpu_sequence.hpp
dv/cpu_sequencer.hpp
dv/cpu_scenario_item.hpp
dv/cpu_util.hpp
dv/cpu_util.cpp
)

target_link_libraries(sim PRIVATE dut)
target_link_libraries(sim PRIVATE uvm-systemc)
