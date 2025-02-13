#ifndef CPU_SEQ_ITEM_H
#define CPU_SEQ_ITEM_H

#include <systemc>
#include <uvm>

#include <cstdint>

// Transaction object used by drivers at CPU interface
class cpu_seq_item : public uvm::uvm_sequence_item {
  public:
    cpu_seq_item(const std::string &name = "cpu_seq_item")
        : uvm::uvm_sequence_item(name), idata(0), data(0), rst_n(true) {}

    ~cpu_seq_item() {}

    UVM_OBJECT_UTILS(cpu_seq_item);

    // DUT input
    bool rst_n;
    std::uint32_t idata;
    std::uint32_t data;

    // DUT output
    std::uint32_t iaddr;
    std::uint32_t addr;
    bool wr;
    std::uint32_t wdata;
    std::uint32_t byte_en;
    std::uint32_t ibyte_en;

    virtual void do_print(uvm::uvm_printer &printer) const {}

    virtual void do_pack(uvm::uvm_packer &packer) const {}

    virtual void do_unpack(uvm::uvm_packer &packer) {}

    virtual void do_copy(const uvm::uvm_object *rhs) {
        const cpu_seq_item *rhs_ = dynamic_cast<const cpu_seq_item *>(rhs);
        idata = rhs_->idata;
        data = rhs_->data;
        iaddr = rhs_->iaddr;
        addr = rhs_->addr;
        wdata = rhs_->wdata;
        wr = rhs_->wr;
        rst_n = rhs_->rst_n;
        byte_en = rhs_->byte_en;
        ibyte_en = rhs_->ibyte_en;
    }

    virtual bool do_compare(const uvm::uvm_object *rhs) const {
        const cpu_seq_item *rhs_ = dynamic_cast<const cpu_seq_item *>(rhs);
        return (idata == rhs_->idata && data == rhs_->data &&
                iaddr == rhs_->iaddr && addr == rhs_->addr &&
                wdata == rhs_->wdata && wr == rhs_->wr && rst_n == rhs_->rst_n);
    }
};

#endif
