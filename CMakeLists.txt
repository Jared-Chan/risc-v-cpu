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
add_executable(sim
dv/sc_main.cpp
dv/test_lib.hpp
dv/cpu_agent.hpp
dv/cpu_driver.hpp
dv/cpu_env.hpp
dv/cpu_if.hpp
dv/cpu_monitor.hpp
dv/cpu_scoreboard.hpp
dv/cpu_seq_item.hpp
dv/cpu_seq_lib.hpp
dv/cpu_sequencer.hpp
dv/cpu_scenario_item.hpp
dv/cpu_util.hpp
dv/cpu_util.cpp
dv/cpu_covergroup.hpp
dv/cpu_coverage_subscriber.hpp
)

target_link_libraries(sim PRIVATE dut)
target_link_libraries(sim PRIVATE uvm-systemc)
target_link_libraries(sim PRIVATE z3)
target_link_libraries(sim PRIVATE crave)
target_link_libraries(sim PRIVATE metaSMT)
target_link_libraries(sim PRIVATE cudd)
target_link_libraries(sim PRIVATE glog)
target_link_libraries(sim PRIVATE boost_filesystem)
