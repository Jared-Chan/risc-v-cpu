#ifndef CPU_SEQ_LIB_H
#define CPU_SEQ_LIB_H

#include "cpu_scenario_item.hpp"
#include "cpu_seq_item.hpp"

#include <cstddef>
#include <systemc>
#include <uvm>

class cpu_base_sequence : public uvm::uvm_sequence<cpu_seq_item, cpu_seq_item> {
  public:
    cpu_base_sequence(const std::string &name_)
        : uvm::uvm_sequence<cpu_seq_item, cpu_seq_item>(name_) {}

    UVM_OBJECT_UTILS(cpu_base_sequence);

    ~cpu_base_sequence() {}

    virtual void body() {
        UVM_INFO(this->get_name(), "Starting cpu_base_sequence",
                 uvm::UVM_MEDIUM);
        UVM_INFO(this->get_name(), "Finishing cpu_base_sequence",
                 uvm::UVM_MEDIUM);
    }
};

class cpu_sequence : public cpu_base_sequence {
  public:
    cpu_sequence(const std::string &name_) : cpu_base_sequence(name_) {

        item = cpu_scenario_item::type_id::create("scenario_item");
    }

    UVM_OBJECT_UTILS(cpu_sequence);

    ~cpu_sequence() { cpu_scenario_item::type_id::destroy(item); }

    void body() {
        uvm::uvm_config_db<int>::get(NULL, this->get_full_name(), "length",
                                     length);
        cpu_seq_item *req{};
        cpu_seq_item *rsp{};
        cpu_seq_item *exp_rsp{};

        bool error, first_instruction;

        uvm::uvm_verbosity verbosity;
        uvm::uvm_config_db<uvm::uvm_verbosity>::get(0, "*", "verbosity",
                                                    verbosity);
        uvm::uvm_root::get()->set_report_id_verbosity("scenario_item",
                                                      verbosity);

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
                req = new cpu_seq_item();

                item->get_next_instruction(*req, *rsp);

                this->start_item(req);
                this->finish_item(req);

                if (rsp)
                    delete rsp;
                rsp = new cpu_seq_item();

                this->get_response(rsp);
            }
        }
        delete req;
        delete rsp;

        UVM_INFO(this->get_name(), "Finishing sequence", uvm::UVM_MEDIUM);
    }

  protected:
    int length;
    cpu_scenario_item *item;
};

class cpu_jump_branch_sequence : public cpu_sequence {
  public:
    cpu_jump_branch_sequence(const std::string &name_) : cpu_sequence(name_) {

        item = cpu_jump_branch_scenario_item::type_id::create(
            "jump_branch_scenario_item");
    }

    UVM_OBJECT_UTILS(cpu_jump_branch_sequence);

    ~cpu_jump_branch_sequence() {
        cpu_jump_branch_scenario_item::type_id::destroy(
            static_cast<cpu_jump_branch_scenario_item *>(item));
    }
};

class cpu_load_store_sequence : public cpu_sequence {
  public:
    cpu_load_store_sequence(const std::string &name_) : cpu_sequence(name_) {

        item = cpu_load_store_scenario_item::type_id::create(
            "load_store_scenario_item");
    }

    UVM_OBJECT_UTILS(cpu_load_store_sequence);

    ~cpu_load_store_sequence() {
        cpu_load_store_scenario_item::type_id::destroy(
            static_cast<cpu_load_store_scenario_item *>(item));
    }
};

class cpu_register_sequence : public cpu_sequence {
  public:
    cpu_register_sequence(const std::string &name_) : cpu_sequence(name_) {

        item = cpu_register_scenario_item::type_id::create(
            "register_scenario_item");
    }

    UVM_OBJECT_UTILS(cpu_register_sequence);

    ~cpu_register_sequence() {
        cpu_register_scenario_item::type_id::destroy(
            static_cast<cpu_register_scenario_item *>(item));
    }
};

class cpu_sys_sequence : public cpu_sequence {
  public:
    cpu_sys_sequence(const std::string &name_) : cpu_sequence(name_) {

        item = cpu_sys_scenario_item::type_id::create("sys_scenario_item");
    }

    UVM_OBJECT_UTILS(cpu_sys_sequence);

    ~cpu_sys_sequence() {
        cpu_sys_scenario_item::type_id::destroy(
            static_cast<cpu_sys_scenario_item *>(item));
    }
};

#endif
