#ifndef CPU_IF_H
#define CPU_IF_H

#include <systemc>
#include <uvm>

class cpu_if : public sc_core::sc_module {

  public:
    cpu_if(const sc_core::sc_module_name &name)
        : sc_module(name), addr("addr"), data("data"), rst_n("rst_n"), wr("wr"),
          iaddr("iaddr"), idata("idata"), wdata("wdata"),
          clk("clk", sc_core::sc_time(5, sc_core::SC_NS)) {}

    sc_core::sc_clock clk;
    sc_core::sc_signal<bool, sc_core::SC_MANY_WRITERS> rst_n;
    sc_core::sc_signal<std::uint32_t> idata;
    sc_core::sc_signal<std::uint32_t> data;

    sc_core::sc_signal<std::uint32_t> iaddr;
    sc_core::sc_signal<std::uint32_t> addr;
    sc_core::sc_signal<bool> wr;
    sc_core::sc_signal<std::uint32_t> wdata;
    sc_core::sc_signal<bool> data_addr_strobe;
    sc_core::sc_signal<std::uint32_t> ibyte_en;
    sc_core::sc_signal<std::uint32_t> byte_en;
};

#endif /* ifndef  */
