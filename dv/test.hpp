#include "cpu_env.hpp"
#include "cpu_if.hpp"
#include "cpu_seq_item.hpp"
#include "cpu_sequence.hpp"
#include "uvmsc/base/uvm_object_globals.h"
#include <string>
#include <systemc>
#include <uvm>

class base_test : public uvm::uvm_test {
  public:
    cpu_if *vif;
    cpu_env *env;
    cpu_sequence<cpu_seq_item> *seq;

    UVM_COMPONENT_UTILS(base_test);

    base_test(uvm::uvm_component_name name)
        : uvm::uvm_test(name), vif(nullptr), env(nullptr) {}
    ~base_test() {}

    void build_phase(uvm::uvm_phase &phase) {
        std::cout << sc_core::sc_time_stamp() << ": " << get_full_name()
                  << " phase: " << phase.get_name() << std::endl;
        env = cpu_env::type_id::create("env");
        seq = cpu_sequence<cpu_seq_item>::type_id::create("seq");

        uvm::uvm_set_config_int(get_full_name() + ".env.agent", "is_active",
                                uvm::UVM_ACTIVE);
    }

    void connect_phase(uvm::uvm_phase &phase) {
        uvm::uvm_config_db<cpu_if *>::get(this, "*.cif1.*", "vif", vif);
    }

    void end_of_elaboration_phase(uvm::uvm_phase &phase) {
        UVM_INFO(get_type_name(), "Test topology :\n" + this->sprint(),
                 uvm::UVM_LOW);
    }

    void start_of_simulation_phase(uvm::uvm_phase &phase) {}

    void extract_phase(uvm::uvm_phase &phase) {}

    void check_phase(uvm::uvm_phase &phase) {}

    void report_phase(uvm::uvm_phase &phase) {}

    void final_phase(uvm::uvm_phase &phase) {
        std::cout << sc_core::sc_time_stamp() << ": " << get_full_name()
                  << " phase: " << phase.get_name() << std::endl;
    }

    void run_phase(uvm::uvm_phase &phase) {
        phase.raise_objection(this);
        std::cout << sc_core::sc_time_stamp() << ": " << get_full_name()
                  << " start phase: " << phase.get_name() << std::endl;

        apply_reset();

        seq->start(env->agent->sequencer);

        /*wait(5, sc_core::SC_MS);*/

        std::cout << sc_core::sc_time_stamp() << ": " << get_full_name()
                  << " end phase: " << phase.get_name() << std::endl;
        phase.drop_objection(this);
    }

    void apply_reset() {
        sc_core::wait(vif->clk.negedge_event());
        vif->rst_n = false;
        sc_core::wait(vif->clk.posedge_event());
        sc_core::wait(vif->clk.negedge_event());
        vif->rst_n = true;
    }
};
