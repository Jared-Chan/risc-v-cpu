cmake_minimum_required(VERSION 3.27)
set (CMAKE_CXX_STANDARD 17)

project(riscv-cpu)
find_package(verilator)

include_directories($ENV{UVM_SYSTEMC_INCLUDE})
link_directories($ENV{UVM_SYSTEMC_LIBDIR})

# --- CRAVE ---
include_directories($ENV{CRAVE_INCLUDE})
link_directories($ENV{CRAVE_LIBDIR})
include_directories($ENV{CRAVE_UVM_INCLUDE})
# link_libraries(crave)
# link_libraries(metaSMT)

include_directories($ENV{Z3_INCLUDE})
link_directories($ENV{Z3_LIBDIR})
# link_libraries(z3)

include_directories($ENV{CUDD_INCLUDE})
link_directories($ENV{CUDD_LIBDIR})
# link_libraries(cudd)

include_directories($ENV{GLOG_INCLUDE})
link_directories($ENV{GLOG_LIBDIR})
# link_libraries(glog)

include_directories($ENV{BOOST_INCLUDE})
link_directories($ENV{BOOST_LIBDIR})
# link_libraries(boost_filesystem)
# -------------

# FC4SC
include_directories($ENV{FC4SC_INCLUDE})

# Design
add_library(dut)
verilate(dut
SYSTEMC
SOURCES rtl/cpu.sv
INCLUDE_DIRS rtl/
)
verilator_link_systemc(dut)

# Testbench
add_executable(cpu_sim
dv/cpu/sc_main.cpp
dv/cpu/test_lib.hpp
dv/cpu/cpu_agent.hpp
dv/cpu/cpu_driver.hpp
dv/cpu/cpu_env.hpp
dv/cpu/cpu_if.hpp
dv/cpu/cpu_monitor.hpp
dv/cpu/cpu_scoreboard.hpp
dv/cpu/cpu_seq_item.hpp
dv/cpu/cpu_seq_lib.hpp
dv/cpu/cpu_sequencer.hpp
dv/cpu/cpu_scenario_item.hpp
dv/cpu/cpu_util.hpp
dv/cpu/cpu_util.cpp
dv/cpu/cpu_covergroup.hpp
dv/cpu/cpu_coverage_subscriber.hpp
)

target_link_libraries(cpu_sim PRIVATE dut)
target_link_libraries(cpu_sim PRIVATE uvm-systemc)
target_link_libraries(cpu_sim PRIVATE z3)
target_link_libraries(cpu_sim PRIVATE crave)
target_link_libraries(cpu_sim PRIVATE metaSMT)
target_link_libraries(cpu_sim PRIVATE cudd)
target_link_libraries(cpu_sim PRIVATE glog)
target_link_libraries(cpu_sim PRIVATE boost_filesystem)
