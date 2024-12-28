#ifndef CPU_SCOREBOARD
#define CPU_SCOREBOARD

#include <systemc>
#include <uvm>

#include "cpu_seq_item.hpp"

class cpu_scoreboard : public uvm::uvm_scoreboard {
  public:
    uvm::uvm_analysis_imp<cpu_seq_item, cpu_scoreboard> cpu_item_export;

    UVM_COMPONENT_UTILS(cpu_scoreboard);

    cpu_scoreboard(uvm::uvm_component_name name)
        : uvm::uvm_scoreboard(name), cpu_item_export("cpu_item_export", this), 
    writes(0) {}

    virtual void write(const cpu_seq_item &item) {
        ++writes;
    }

    virtual void report_phase(uvm::uvm_phase &phase) {
    UVM_INFO(get_type_name(), "Reporting scoreboard information...\n" +
        this->sprint(), uvm::UVM_LOW);
    }

  protected:
    int writes;
};

#endif
