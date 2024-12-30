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
        REQ *req;
        RSP *rsp;
        RSP *exp_rsp;

        bool error;

        UVM_INFO(this->get_name(), "Starting sequence", uvm::UVM_MEDIUM);
        for (int i = 0; i < 2; ++i) {

            if (!item.randomize()) {
                UVM_INFO(this->get_name(), "Randomization failed.",
                         uvm::UVM_INFO);
            } else {
                UVM_INFO(this->get_name(), "Randomization succeeded.",
                         uvm::UVM_INFO);
            }
            /*item.r_iaddr() = 0x30;*/
            item.generate_instructions();

            while (item.has_next_instruction()) {
                req = new REQ();
                rsp = new RSP();
                exp_rsp = new RSP();
                error = false;

                item.get_next_instruction(*req, *exp_rsp);
                this->start_item(req);
                this->finish_item(req);
                this->get_response(rsp);

                if (!cpu_util::is_nop(*req) && !cpu_util::is_nop(*exp_rsp)) {
                    if ((req->idata & 0x3F) ==
                            static_cast<std::uint32_t>(cpu_util::Opcode::L) ||
                        (req->idata & 0x3F) ==
                            static_cast<std::uint32_t>(cpu_util::Opcode::S)) {
                        error = !(rsp->iaddr == exp_rsp->iaddr &&
                                  rsp->addr == exp_rsp->addr &&
                                  rsp->data == exp_rsp->data &&
                                  rsp->wr == exp_rsp->wr);
                    } else {
                        error = !(rsp->iaddr == exp_rsp->iaddr &&
                                  rsp->wr == exp_rsp->wr);
                    }
                }
                if (error) {
                    UVM_ERROR(this->get_name(), "Unexpected response. ");
                }
                delete req;
                delete rsp;
                delete exp_rsp;
            }
        }

        UVM_INFO(this->get_name(), "Finishing sequence", uvm::UVM_MEDIUM);
    }

  protected:
    int length;
    cpu_scenario_item item;
};

#endif
