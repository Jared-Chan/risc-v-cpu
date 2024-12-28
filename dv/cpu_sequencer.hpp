
#ifndef CPU_SEQUENCER
#define CPU_SEQUENCER

#include <systemc>
#include <uvm>

#include "cpu_seq_item.hpp"

class cpu_sequencer : public uvm::uvm_sequencer<cpu_seq_item> {
  public:
    UVM_COMPONENT_UTILS(cpu_sequencer);

    cpu_sequencer(uvm::uvm_component_name name)
        : uvm::uvm_sequencer<cpu_seq_item>(name) {}
};

#endif
