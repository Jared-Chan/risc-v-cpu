#ifndef CPU_AGENT_H
#define CPU_AGENT_H

#include "cpu_driver.hpp"
#include "cpu_if.hpp"
#include "cpu_monitor.hpp"
#include "cpu_sequencer.hpp"

#include <systemc>
#include <uvm>

class cpu_agent : public uvm::uvm_agent {
  public:
    cpu_sequencer *sequencer;
    cpu_driver *driver;
    cpu_monitor *monitor;

    cpu_if *vif;

    UVM_COMPONENT_UTILS(cpu_agent);

    cpu_agent(uvm::uvm_component_name name)
        : uvm::uvm_agent(name), sequencer(nullptr), driver(nullptr),
          monitor(nullptr), vif(nullptr) {}

    ~cpu_agent() {
        if (sequencer)
            delete sequencer;
        if (driver)
            delete driver;
        if (monitor)
            delete monitor;
    }

    virtual void build_phase(uvm::uvm_phase &phase) {
        uvm::uvm_agent::build_phase(phase);

        monitor = cpu_monitor::type_id::create("monitor", this);
        assert(monitor);

        if (get_is_active() == uvm::UVM_ACTIVE) {
            sequencer = cpu_sequencer::type_id::create("sequencer", this);
            assert(sequencer);
            driver = cpu_driver::type_id::create("driver", this);
            assert(driver);
        }

        if (!uvm::uvm_config_db<cpu_if *>::get(this, "", "vif", vif)) {
            UVM_FATAL("NOVIF",
                      "No virtual interface specified for this agent instance");
        }
    }

    virtual void connect_phase(uvm::uvm_phase &phase) {
        if (get_is_active() == uvm::UVM_ACTIVE) {
            driver->seq_item_port.connect(sequencer->seq_item_export);
        }
    }
};

#endif
