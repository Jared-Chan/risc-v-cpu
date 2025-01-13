#include "Vcpu.h"
#include "cpu_if.hpp"
#include "test_lib.hpp"

#include <systemc>
#include <uvm>

int sc_main(int, char *[]) {

    Vcpu *dut = new Vcpu("dut");
    cpu_if *cif = new cpu_if("cif");

    dut->addr_o.bind(cif->addr);
    dut->data_i.bind(cif->data);
    dut->wdata_o.bind(cif->wdata);
    dut->idata_i.bind(cif->idata);
    dut->iaddr_o.bind(cif->iaddr);
    dut->wr_o.bind(cif->wr);
    dut->rst_n.bind(cif->rst_n);
    dut->clk.bind(cif->clk);
    dut->data_addr_strobe_o.bind(cif->data_addr_strobe);
    dut->ibyte_en_o.bind(cif->ibyte_en);
    dut->byte_en_o.bind(cif->byte_en);

    uvm::uvm_config_db<cpu_if *>::set(uvm::uvm_root::get(), "*", "vif", cif);
    uvm::uvm_config_db<int>::set(uvm::uvm_root::get(),
                                 "*.env.agent.sequencer.seq", "length",
                                 10000);
    uvm::uvm_config_db<uvm::uvm_verbosity>::set(uvm::uvm_root::get(), "*",
                                                "verbosity", uvm::UVM_LOW);
    crave::init("crave.cfg");

    uvm::run_test("complete_test");

    xml_printer::coverage_save("coverage_results.xml");

    return 0;
}
