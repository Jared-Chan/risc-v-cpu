#ifndef CPU_IF
#define CPU_IF

#include <systemc>
#include <uvm>

class cpu_if : public sc_core::sc_module {

  public:
    cpu_if(const sc_core::sc_module_name &name)
        : sc_module(name), addr("addr"), data("data"), rst_n("rst_n"), wr("wr"),
          iaddr("iaddr"), idata("idata"), wdata("wdata"), clk("clk", 5) {}

    sc_core::sc_clock clk;
    sc_core::sc_signal<bool> rst_n;
    sc_core::sc_signal<std::uint32_t> idata;
    sc_core::sc_signal<std::uint32_t> data;

    sc_core::sc_signal<std::uint32_t> iaddr;
    sc_core::sc_signal<std::uint32_t> addr;
    sc_core::sc_signal<bool> wr;
    sc_core::sc_signal<std::uint32_t> wdata;
};

#endif /* ifndef  */
