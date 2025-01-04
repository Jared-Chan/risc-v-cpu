#ifndef CPU_COVERAGE_SUBSCRIBER_H
#define CPU_COVERAGE_SUBSCRIBER_H

#include "cpu_seq_item.hpp"
#include "cpu_covergroup.hpp"
#include "uvmsc/comps/uvm_subscriber.h"

#include <systemc>
#include <uvm>

class cpu_coverage_subscriber : public uvm::uvm_subscriber<cpu_seq_item> {

  public:
    UVM_COMPONENT_UTILS(cpu_coverage_subscriber);

    cpu_covergroup cg;

    cpu_coverage_subscriber(uvm::uvm_component_name name)
        : uvm::uvm_subscriber<cpu_seq_item>(name) {}

    virtual void write(const cpu_seq_item &i) {
        cpu_seq_item item = i;
        cg.sample(item);
    }
};

#endif
