#ifndef CPU_DRIVER
#define CPU_DRIVER

#include <cstdint>
#include <systemc>
#include <uvm>

#include "cpu_if.hpp"
#include "cpu_seq_item.hpp"
#include "cpu_util.hpp"

class cpu_driver : public uvm::uvm_driver<cpu_seq_item> {
  public:
    cpu_driver(uvm::uvm_component_name name)
        : uvm::uvm_driver<cpu_seq_item>(name) {}

    UVM_COMPONENT_UTILS(cpu_driver);

    cpu_if *vif;

    void build_phase(uvm::uvm_phase &phase) {
        uvm::uvm_driver<cpu_seq_item>::build_phase(phase);

        if (!uvm::uvm_config_db<cpu_if *>::get(this, "", "vif", vif))
            UVM_FATAL("NOVIF", "virtual interface must be set for: " +
                                   get_full_name() + ".vif");
    }

    void run_phase(uvm::uvm_phase &phase) {
        cpu_seq_item req;
        cpu_seq_item rsp; // rsp of prev instruction

        while (true) {
            this->seq_item_port->get_next_item(req);

            drive_item(req);

            this->seq_item_port->item_done();

            get_item(rsp, req);

            rsp.set_id_info(req);

            this->seq_item_port->put_response(rsp);
        }
    }

  private:
    void drive_item(cpu_seq_item &req) {
        sc_core::wait(vif->clk.negedge_event());
        vif->idata = req.idata;
        vif->rst_n = req.rst_n;
        vif->data = req.data;
        /*sc_core::wait(vif->clk.posedge_event());*/
    }
    void get_item(cpu_seq_item &rsp, cpu_seq_item &req) {
        sc_core::wait(vif->clk.posedge_event());

        /*// For load and store, wait an extra cycle*/
        /*if ((req.idata & 0x3F) ==*/
        /*        static_cast<std::uint32_t>(cpu_util::Opcode::L) ||*/
        /*    (req.idata & 0x3F) ==*/
        /*        static_cast<std::uint32_t>(cpu_util::Opcode::S)) {*/
        /*    sc_core::wait(vif->clk.posedge_event());*/
        /*}*/
            rsp.iaddr = vif->iaddr;
            rsp.addr = vif->addr;
            rsp.wdata = vif->wdata;
            rsp.wr = vif->wr;
    }
};

#endif
