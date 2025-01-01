#ifndef CPU_SEQUENCE
#define CPU_SEQUENCE

#include "cpu_scenario_item.hpp"
#include "cpu_util.hpp"
#include "uvmsc/base/uvm_object_globals.h"
#include <cstdint>
#include <systemc>
#include <uvm>

template <typename REQ = uvm::uvm_sequence_item, typename RSP = REQ>
class cpu_sequence : public uvm::uvm_sequence<REQ, RSP> {
  public:
    cpu_sequence(const std::string &name_)
        : uvm::uvm_sequence<REQ, RSP>(name_) {}

    UVM_OBJECT_PARAM_UTILS(cpu_sequence<REQ, RSP>);

    void body() {
        REQ *req {};
        RSP *rsp {};
        RSP *exp_rsp {};

        bool error, first_instruction;

        UVM_INFO(this->get_name(), "Starting sequence", uvm::UVM_MEDIUM);
        for (int i = 0; i < 100; ++i) {

            if (!item.randomize()) {
                UVM_INFO(this->get_name(), "Randomization failed.",
                         uvm::UVM_INFO);
            } else {
                UVM_INFO(this->get_name(), "Randomization succeeded.",
                         uvm::UVM_INFO);
            }
            /*item.r_iaddr() = 0x30;*/
            item.generate_instructions();
            
            std::ostringstream info_instr_len;
            info_instr_len << "Total instructions in current sequence ";
            info_instr_len << item.instruction_addresses.size();
            UVM_INFO(this->get_name(), info_instr_len.str(), uvm::UVM_MEDIUM);

            while (item.has_next_instruction()) {
                if (req)
                    delete req;
                req = new REQ();

                item.get_next_instruction(*req, *rsp);

                /*std::cout << std::endl;*/
                /*std::ostringstream str;*/
                /*str << "\nCurrent req: \n";*/
                /*cpu_util::print_instruction(*req, str);*/
                /*UVM_INFO(get_type_name(), str.str(), uvm::UVM_INFO);*/

                this->start_item(req);
                this->finish_item(req);

                if (rsp)
                    delete rsp;
                rsp = new RSP();

                this->get_response(rsp);
            }
        }

        UVM_INFO(this->get_name(), "Finishing sequence", uvm::UVM_MEDIUM);
    }

  protected:
    int length;
    cpu_scenario_item item;
};

#endif
