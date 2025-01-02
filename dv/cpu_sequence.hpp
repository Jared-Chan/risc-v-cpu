#ifndef CPU_SEQUENCE_H
#define CPU_SEQUENCE_H

#include "cpu_scenario_item.hpp"

#include "uvmsc/base/uvm_object_globals.h"
#include <cstddef>
#include <systemc>
#include <uvm>

template <typename REQ = uvm::uvm_sequence_item, typename RSP = REQ>
class cpu_sequence : public uvm::uvm_sequence<REQ, RSP> {
  public:
    cpu_sequence(const std::string &name_)
        : uvm::uvm_sequence<REQ, RSP>(name_) {}

    UVM_OBJECT_PARAM_UTILS(cpu_sequence<REQ, RSP>);

    void body() {
        uvm::uvm_config_db<int>::get(NULL, this->get_full_name(), "length", length);
        REQ *req{};
        RSP *rsp{};
        RSP *exp_rsp{};

        bool error, first_instruction;

        item = cpu_scenario_item::type_id::create("scenario_item");
        uvm::uvm_verbosity verbosity;
        uvm::uvm_config_db<uvm::uvm_verbosity>::get(0, "*", "verbosity",
                                                    verbosity);
        uvm::uvm_root::get()->set_report_id_verbosity("scenario_item",verbosity);

        UVM_INFO(this->get_name(), "Starting sequence", uvm::UVM_MEDIUM);
        for (int i = 0; i < length; ++i) {
            UVM_INFO(this->get_name(), "Starting a new scenario",
                     uvm::UVM_MEDIUM);

            if (!item->randomize()) {
                UVM_ERROR(this->get_name(), "Randomization failed.");
                continue;
            }
            item->generate_instructions();

            while (item->has_next_instruction()) {
                if (req)
                    delete req;
                req = new REQ();

                item->get_next_instruction(*req, *rsp);

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
    cpu_scenario_item *item;
};

#endif
