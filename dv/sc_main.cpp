#include <sysc/communication/sc_clock.h>
#include <systemc>
#include <uvm>

#include "Vcpu.h"
#include "cpu_if.hpp"

#include "test.hpp"

int sc_main(int, char *[]) {

    Vcpu *dut = new Vcpu("dut");
    cpu_if *cif = new cpu_if("cif");

    dut->addr.bind(cif->addr);
    dut->data.bind(cif->data);
    dut->wdata.bind(cif->wdata);
    dut->idata.bind(cif->idata);
    dut->iaddr.bind(cif->iaddr);
    dut->wr.bind(cif->wr);
    dut->rst_n.bind(cif->rst_n);
    dut->clk.bind(cif->clk);

    uvm::uvm_config_db<cpu_if *>::set(0, "*", "vif", cif);

    uvm::run_test("base_test");

    return 0;
}
