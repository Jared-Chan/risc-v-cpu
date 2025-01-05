#ifndef CPU_SCOREBOARD_H
#define CPU_SCOREBOARD_H

#include "cpu_seq_item.hpp"
#include "cpu_util.hpp"

#include <sstream>
#include <systemc>
#include <uvm>

#include <string>

class cpu_scoreboard : public uvm::uvm_scoreboard {
  public:
    uvm::uvm_analysis_imp<cpu_seq_item, cpu_scoreboard> cpu_item_export;

    UVM_COMPONENT_UTILS(cpu_scoreboard);

    cpu_scoreboard(uvm::uvm_component_name name)
        : uvm::uvm_scoreboard(name), cpu_item_export("cpu_item_export", this),
          m_transfers(0) {}

    virtual void write(const cpu_seq_item &item) {
        ++m_transfers;
        if (item.rst_n == false && item.iaddr != 0) {
            std::ostringstream str;
            str << "Error, actual iaddr: 0x" << std::hex << item.iaddr;
            str << " expected iaddr: 0x" << std::hex << 0;
            UVM_ERROR(this->get_name(), str.str());
        }
        std::ostringstream str;
        cpu_util::print_instruction(item, str);
        UVM_INFO(get_type_name(), str.str(), uvm::UVM_HIGH);
    }

    virtual void report_phase(uvm::uvm_phase &phase) {
        std::ostringstream str;
        str << "Total transfers: " << std::right << std::setw(37)
            << std::to_string(m_transfers) << std::endl;
        str << std::string(54, '-') << std::endl;

        UVM_INFO(get_type_name(),
                 "Reporting scoreboard information...\n" + this->sprint() + str.str(),
                 uvm::UVM_LOW);
    }

    virtual void do_print(uvm::uvm_printer &printer) const {
        this->do_print(printer);
        printer.print_field_int("m_transfers", m_transfers, 32, uvm::UVM_DEC);
    }

    /*protected:*/
    int m_transfers;
};

#endif
