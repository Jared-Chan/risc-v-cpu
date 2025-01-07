#ifndef CPU_MONITOR_H
#define CPU_MONITOR_H

#include "cpu_if.hpp"
#include "cpu_seq_item.hpp"

#include <systemc>
#include <uvm>

class cpu_monitor : public uvm::uvm_monitor {
  public:
    uvm::uvm_analysis_port<cpu_seq_item> cpu_item_port;

    UVM_COMPONENT_UTILS(cpu_monitor);

    cpu_monitor(uvm::uvm_component_name name) : uvm::uvm_monitor(name) {}

    void build_phase(uvm::uvm_phase &phase) {
        if (!uvm::uvm_config_db<cpu_if *>::get(this, "", "vif", vif))
            UVM_FATAL("NOVIF", "virtual interface must be set for: " +
                                   get_full_name() + ".vif");
    }
    void run_phase(uvm::uvm_phase &phase) {
        SC_FORK
        sc_core::sc_spawn(sc_core::sc_bind(&cpu_monitor::observe_reset, this)),
            sc_core::sc_spawn(
                sc_core::sc_bind(&cpu_monitor::observe_clock, this)),
            SC_JOIN
    }

    void observe_reset() {
        SC_FORK
        sc_core::sc_spawn(
            sc_core::sc_bind(&cpu_monitor::check_reset_on_negedge, this)),
            sc_core::sc_spawn(
                sc_core::sc_bind(&cpu_monitor::check_reset_on_posedge, this)),
            SC_JOIN
    }
    void check_reset_on_posedge() {
        while (true) {
            sc_core::wait(vif->rst_n.posedge_event());
        }
    }
    void check_reset_on_negedge() {
        while (true) {
            sc_core::wait(vif->rst_n.negedge_event());
            item.rst_n = vif->rst_n;
            item.idata = vif->idata;
            item.data = vif->data;
            item.iaddr = vif->iaddr;
            item.addr = vif->addr;
            item.wr = vif->wr;
            item.wdata = vif->wdata;
            cpu_item_port.write(item);
        }
    }
    void observe_clock() {
        while (true) {
            sc_core::wait(vif->clk.posedge_event());
            item.rst_n = vif->rst_n;
            item.idata = vif->idata;
            item.data = vif->data;
            item.iaddr = vif->iaddr;
            item.addr = vif->addr;
            item.wr = vif->wr;
            item.wdata = vif->wdata;
            cpu_item_port.write(item);
        }
    }

  protected:
    cpu_if *vif;
    cpu_seq_item item;
};

#endif
