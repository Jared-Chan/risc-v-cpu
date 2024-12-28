#include "cpu_env.hpp"
#include "cpu_if.hpp"
#include "cpu_seq_item.hpp"
#include "cpu_sequence.hpp"
#include <systemc>
#include <uvm>

class test : public uvm::uvm_test {
  public:
    cpu_if *vif;
    cpu_env *env;
    cpu_sequence<cpu_seq_item> *seq;

    UVM_COMPONENT_UTILS(test);

    test(uvm::uvm_component_name name) : uvm::uvm_test(name), vif(nullptr),
    env(nullptr){}
    ~test() {}

    void build_phase(uvm::uvm_phase &phase) {
        std::cout << sc_core::sc_time_stamp() << ": " << get_full_name()
                  << " phase: " << phase.get_name() << std::endl;
        env = cpu_env::type_id::create("env");
        seq = cpu_sequence<cpu_seq_item>::type_id::create("seq");

        uvm::uvm_set_config_int("test.env.agent", "is_active", uvm::UVM_ACTIVE);
    }

    void connect_phase(uvm::uvm_phase &phase) {
        uvm::uvm_config_db<cpu_if *>::get(this, "*.cif1.*", "vif", vif);
    }

    void end_of_elaboration_phase(uvm::uvm_phase &phase) {}

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

        seq->start(env->agent->sequencer);

        wait(50, sc_core::SC_MS);

        std::cout << sc_core::sc_time_stamp() << ": " << get_full_name()
                  << " end phase: " << phase.get_name() << std::endl;
        phase.drop_objection(this);
    }
};
