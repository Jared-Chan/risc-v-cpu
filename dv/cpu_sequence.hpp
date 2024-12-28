#ifndef CPU_SEQUENCE
#define CPU_SEQUENCE

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
        rsp = new RSP();

        UVM_INFO(this->get_name(), "Starting sequence", uvm::UVM_MEDIUM);

        req = new REQ();
        req->rst_n = false;

        this->start_item(req);
        this->finish_item(req);
        this->get_response(rsp);

        delete req;

        req = new REQ();
        req->rst_n = true;

        this->start_item(req);
        this->finish_item(req);
        this->get_response(rsp);

        delete req;

        if (rsp->iaddr != 0) {
            std::ostringstream str;
            str << "Error, actual iaddr: 0x" << std::hex << rsp->iaddr;
            str << " expected iaddr: 0x" << std::hex << 0;
            UVM_ERROR(this->get_name(), str.str());
        }
        
        delete rsp;

        UVM_INFO(this->get_name(), "Finishing sequence", uvm::UVM_MEDIUM);
    }
};

#endif
