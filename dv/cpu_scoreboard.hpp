#ifndef CPU_SCOREBOARD
#define CPU_SCOREBOARD

#include <systemc>
#include <uvm>

#include "cpu_seq_item.hpp"
#include "uvmsc/macros/uvm_message_defines.h"

class cpu_scoreboard : public uvm::uvm_scoreboard {
  public:
    uvm::uvm_analysis_imp<cpu_seq_item, cpu_scoreboard> cpu_item_export;

    UVM_COMPONENT_UTILS(cpu_scoreboard);

    cpu_scoreboard(uvm::uvm_component_name name)
        : uvm::uvm_scoreboard(name), cpu_item_export("cpu_item_export", this), 
    writes(0) {}

    virtual void write(const cpu_seq_item &item) {
        ++writes;
        if (item.rst_n == false && item.iaddr != 0) {
            std::ostringstream str;
            str << "Error, actual iaddr: 0x" << std::hex << item.iaddr;
            str << " expected iaddr: 0x" << std::hex << 0;
            UVM_ERROR(this->get_name(), str.str());
        }
    }

    virtual void report_phase(uvm::uvm_phase &phase) {
    UVM_INFO(get_type_name(), "Reporting scoreboard information...\n" +
        this->sprint(), uvm::UVM_LOW);
    }

  protected:
    int writes;
};

#endif
