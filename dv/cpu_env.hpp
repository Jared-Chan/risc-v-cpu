#ifndef CPU_ENF
#define CPU_ENF

#include <systemc>
#include <uvm>

#include "cpu_agent.hpp"
#include "cpu_scoreboard.hpp"
#include "uvmsc/base/uvm_object_globals.h"

//------------------------------------------------------------------------------
// Class: ubus_env
//------------------------------------------------------------------------------

class cpu_env : public uvm::uvm_env {
  public:
    cpu_scoreboard *scoreboard;
    cpu_agent *agent;

    UVM_COMPONENT_UTILS(cpu_env);

    cpu_env(uvm::uvm_component_name name) : uvm::uvm_env(name) {}

    void build_phase(uvm::uvm_phase &phase) {

        uvm_env::build_phase(phase);

        if (!uvm::uvm_config_db<cpu_if *>::get(this, "", "vif", vif))
            UVM_FATAL("NOVIF", "virtual interface must be set for: " +
                                   get_full_name() + ".vif");

        agent = cpu_agent::type_id::create("agent");
        scoreboard = cpu_scoreboard::type_id::create("scoreboard");
    }

    virtual void connect_phase(uvm::uvm_phase &phase) {
        agent->monitor->cpu_item_port.connect(scoreboard->cpu_item_export);
    }
    void run_phase(uvm::uvm_phase &phase) {}

  protected:
    cpu_if *vif;
};

#endif

