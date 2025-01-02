#ifndef CPU_ENV_H
#define CPU_ENV_H

#include "cpu_agent.hpp"
#include "cpu_coverage_subscriber.hpp"
#include "cpu_scoreboard.hpp"

#include <systemc>
#include <uvm>

class cpu_env : public uvm::uvm_env {
  public:
    cpu_scoreboard *scoreboard;
    cpu_agent *agent;
    cpu_coverage_subscriber *coverage_subscriber;

    UVM_COMPONENT_UTILS(cpu_env);

    cpu_env(uvm::uvm_component_name name) : uvm::uvm_env(name) {}

    void build_phase(uvm::uvm_phase &phase) {

        uvm_env::build_phase(phase);

        if (!uvm::uvm_config_db<cpu_if *>::get(this, "", "vif", vif))
            UVM_FATAL("NOVIF", "virtual interface must be set for: " +
                                   get_full_name() + ".vif");

        agent = cpu_agent::type_id::create("agent");
        scoreboard = cpu_scoreboard::type_id::create("scoreboard");
        coverage_subscriber = cpu_coverage_subscriber::type_id::create("coverage_subscriber");
    }

    virtual void connect_phase(uvm::uvm_phase &phase) {
        agent->monitor->cpu_item_port.connect(scoreboard->cpu_item_export);
        agent->monitor->cpu_item_port.connect(coverage_subscriber->analysis_export);
    }
    void run_phase(uvm::uvm_phase &phase) {}

  protected:
    cpu_if *vif;
};

#endif
