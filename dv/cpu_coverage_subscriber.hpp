#ifndef CPU_COVERAGE_SUBSCRIBER_H
#define CPU_COVERAGE_SUBSCRIBER_H

#include "cpu_seq_item.hpp"
#include "cpu_util.hpp"
#include "uvmsc/comps/uvm_subscriber.h"

#include "fc4sc.hpp"

#include <cstdint>
#include <systemc>
#include <uvm>
#include <vector>

class cpu_covergroup : public covergroup {
  public:
    bool rst_n;
    std::uint32_t idata;
    std::uint32_t data;
    std::uint32_t iaddr;
    std::uint32_t addr;
    bool wr;
    std::uint32_t wdata;

    std::uint8_t data4;
    std::uint8_t iaddr4;
    std::uint8_t addr4;
    std::uint8_t wdata4;

    cpu_util::Opcode opcode;
    cpu_util::F3 f3;
    cpu_util::F7 f7;
    std::uint8_t rs1;
    std::uint8_t rs2;
    std::uint8_t rd;
    std::uint32_t i_imm;
    std::uint32_t s_imm;
    std::uint32_t u_imm;
    std::uint32_t b_imm;
    std::uint32_t j_imm;
    std::uint8_t opcode_u;
    std::uint8_t f3_u;
    std::uint8_t f7_u;

    CG_CONS(cpu_covergroup) {}

    void sample(cpu_seq_item &item) {
        rst_n = item.rst_n;
        idata = item.idata;
        data = item.data;
        iaddr = item.iaddr;
        addr = item.addr;
        wr = item.wr;
        wdata = item.wdata;

        data4 = data & 0xF;
        iaddr4 = iaddr & 0xF;
        addr4 = addr & 0xF;
        wdata4 = wdata & 0xF;

        cpu_util::decode_idata(item, opcode, f3, f7, rs1, rs2, rd, i_imm, s_imm,
                               u_imm, b_imm, j_imm);
        opcode_u = static_cast<std::uint8_t>(opcode);
        f3_u = static_cast<std::uint8_t>(f3);
        f7_u = static_cast<std::uint8_t>(f7);
        covergroup::sample();
    }

    COVERPOINT(bool, rst_n_cvp, rst_n){bin<bool>("normal", true),
                                       bin<bool>("reset", false)};

    COVERPOINT(bool, wr_cvp, wr){bin<bool>("write", true),
                                 bin<bool>("read", false)};

    std::uint32_t bin_size = 0xFFFFFFFF / 8;
    COVERPOINT(std::uint32_t, data_msb_cvp, data){
        bin<std::uint32_t>("0",
                           fc4sc::interval(bin_size * 0, bin_size * 1 - 1)),
        bin<std::uint32_t>("1",
                           fc4sc::interval(bin_size * 1, bin_size * 2 - 1)),
        bin<std::uint32_t>("2",
                           fc4sc::interval(bin_size * 2, bin_size * 3 - 1)),
        bin<std::uint32_t>("3",
                           fc4sc::interval(bin_size * 3, bin_size * 4 - 1)),
        bin<std::uint32_t>("4",
                           fc4sc::interval(bin_size * 4, bin_size * 5 - 1)),
        bin<std::uint32_t>("5",
                           fc4sc::interval(bin_size * 5, bin_size * 6 - 1)),
        bin<std::uint32_t>("6",
                           fc4sc::interval(bin_size * 6, bin_size * 7 - 1)),
        bin<std::uint32_t>("7",
                           fc4sc::interval(bin_size * 7, bin_size * 8 - 1))};

    COVERPOINT(std::uint32_t, wdata_msb_cvp, wdata){
        bin<std::uint32_t>("0",
                           fc4sc::interval(bin_size * 0, bin_size * 1 - 1)),
        bin<std::uint32_t>("1",
                           fc4sc::interval(bin_size * 1, bin_size * 2 - 1)),
        bin<std::uint32_t>("2",
                           fc4sc::interval(bin_size * 2, bin_size * 3 - 1)),
        bin<std::uint32_t>("3",
                           fc4sc::interval(bin_size * 3, bin_size * 4 - 1)),
        bin<std::uint32_t>("4",
                           fc4sc::interval(bin_size * 4, bin_size * 5 - 1)),
        bin<std::uint32_t>("5",
                           fc4sc::interval(bin_size * 5, bin_size * 6 - 1)),
        bin<std::uint32_t>("6",
                           fc4sc::interval(bin_size * 6, bin_size * 7 - 1)),
        bin<std::uint32_t>("7",
                           fc4sc::interval(bin_size * 7, bin_size * 8 - 1))};

    COVERPOINT(std::uint32_t, iaddr_msb_cvp, iaddr){
        bin<std::uint32_t>("0",
                           fc4sc::interval(bin_size * 0, bin_size * 1 - 1)),
        bin<std::uint32_t>("1",
                           fc4sc::interval(bin_size * 1, bin_size * 2 - 1)),
        bin<std::uint32_t>("2",
                           fc4sc::interval(bin_size * 2, bin_size * 3 - 1)),
        bin<std::uint32_t>("3",
                           fc4sc::interval(bin_size * 3, bin_size * 4 - 1)),
        bin<std::uint32_t>("4",
                           fc4sc::interval(bin_size * 4, bin_size * 5 - 1)),
        bin<std::uint32_t>("5",
                           fc4sc::interval(bin_size * 5, bin_size * 6 - 1)),
        bin<std::uint32_t>("6",
                           fc4sc::interval(bin_size * 6, bin_size * 7 - 1)),
        bin<std::uint32_t>("7",
                           fc4sc::interval(bin_size * 7, bin_size * 8 - 1))};

    COVERPOINT(std::uint32_t, addr_msb_cvp, addr){
        bin<std::uint32_t>("0",
                           fc4sc::interval(bin_size * 0, bin_size * 1 - 1)),
        bin<std::uint32_t>("1",
                           fc4sc::interval(bin_size * 1, bin_size * 2 - 1)),
        bin<std::uint32_t>("2",
                           fc4sc::interval(bin_size * 2, bin_size * 3 - 1)),
        bin<std::uint32_t>("3",
                           fc4sc::interval(bin_size * 3, bin_size * 4 - 1)),
        bin<std::uint32_t>("4",
                           fc4sc::interval(bin_size * 4, bin_size * 5 - 1)),
        bin<std::uint32_t>("5",
                           fc4sc::interval(bin_size * 5, bin_size * 6 - 1)),
        bin<std::uint32_t>("6",
                           fc4sc::interval(bin_size * 6, bin_size * 7 - 1)),
        bin<std::uint32_t>("7",
                           fc4sc::interval(bin_size * 7, bin_size * 8 - 1))};

    std::vector<std::uint8_t> four_bits{0, 1, 2,  3,  4,  5,  6,  7,
                                        8, 9, 10, 11, 12, 13, 14, 15};
    std::vector<std::uint8_t> four_mul{0, 4, 8, 12};

    COVERPOINT(std::uint8_t, data_lsb_cvp,
               data4){bin_array<std::uint8_t>("data_lsb", four_bits)};
    COVERPOINT(std::uint8_t, wdata_lsb_cvp,
               wdata4){bin_array<std::uint8_t>("wdata_lsb", four_bits)};
    COVERPOINT(std::uint8_t, addr_lsb_cvp,
               addr4){bin_array<std::uint8_t>("addr_lsb", four_bits)};
    COVERPOINT(std::uint8_t, iaddr_lsb_cvp,
               iaddr4){bin_array<std::uint8_t>("iaddr_lsb", four_mul)};

    COVERPOINT(std::uint8_t, opcode_cvp, opcode_u){
        bin<std::uint8_t>("LUI",
                          static_cast<std::uint8_t>(cpu_util::Opcode::LUI)),
        bin<std::uint8_t>("AUIPC",
                          static_cast<std::uint8_t>(cpu_util::Opcode::AUIPC)),
        bin<std::uint8_t>("JAL",
                          static_cast<std::uint8_t>(cpu_util::Opcode::JAL)),
        bin<std::uint8_t>("JALR",
                          static_cast<std::uint8_t>(cpu_util::Opcode::JALR)),
        bin<std::uint8_t>("B", static_cast<std::uint8_t>(cpu_util::Opcode::B)),
        bin<std::uint8_t>("L", static_cast<std::uint8_t>(cpu_util::Opcode::L)),
        bin<std::uint8_t>("S", static_cast<std::uint8_t>(cpu_util::Opcode::S)),
        bin<std::uint8_t>("RI",
                          static_cast<std::uint8_t>(cpu_util::Opcode::RI)),
        bin<std::uint8_t>("RR",
                          static_cast<std::uint8_t>(cpu_util::Opcode::RR)),
        bin<std::uint8_t>("F", static_cast<std::uint8_t>(cpu_util::Opcode::F)),
        bin<std::uint8_t>("E", static_cast<std::uint8_t>(cpu_util::Opcode::E))};

    COVERPOINT(std::uint8_t, b_f3_cvp, f3_u, opcode == cpu_util::Opcode::B){
        bin<std::uint8_t>("BEQ", static_cast<std::uint8_t>(cpu_util::F3::BEQ)),
        bin<std::uint8_t>("BNE", static_cast<std::uint8_t>(cpu_util::F3::BNE)),
        bin<std::uint8_t>("BLT", static_cast<std::uint8_t>(cpu_util::F3::BLT)),
        bin<std::uint8_t>("BGE", static_cast<std::uint8_t>(cpu_util::F3::BGE)),
        bin<std::uint8_t>("BLTU",
                          static_cast<std::uint8_t>(cpu_util::F3::BLTU)),
        bin<std::uint8_t>("BGEU",
                          static_cast<std::uint8_t>(cpu_util::F3::BGEU))};

    COVERPOINT(std::uint8_t, l_f3_cvp, f3_u, opcode == cpu_util::Opcode::L){
        bin<std::uint8_t>("LB", static_cast<std::uint8_t>(cpu_util::F3::LB)),
        bin<std::uint8_t>("LH", static_cast<std::uint8_t>(cpu_util::F3::LH)),
        bin<std::uint8_t>("LW", static_cast<std::uint8_t>(cpu_util::F3::LW)),
        bin<std::uint8_t>("LBU", static_cast<std::uint8_t>(cpu_util::F3::LBU)),
        bin<std::uint8_t>("LHU", static_cast<std::uint8_t>(cpu_util::F3::LHU))};

    COVERPOINT(std::uint8_t, s_f3_cvp, f3_u,
               opcode_u == static_cast<std::uint8_t>(cpu_util::Opcode::S)){
        bin<std::uint8_t>("SW", static_cast<std::uint8_t>(cpu_util::F3::SW)),
        bin<std::uint8_t>("SH", static_cast<std::uint8_t>(cpu_util::F3::SH)),
        bin<std::uint8_t>("SB", static_cast<std::uint8_t>(cpu_util::F3::SB))};

    COVERPOINT(std::uint8_t, alu_f3_cvp, f3_u,
               opcode == cpu_util::Opcode::RR ||
                   opcode == cpu_util::Opcode::RI){
        bin<std::uint8_t>("ADDSUB",
                          static_cast<std::uint8_t>(cpu_util::F3::ADDSUB)),
        bin<std::uint8_t>("SLT", static_cast<std::uint8_t>(cpu_util::F3::SLT)),
        bin<std::uint8_t>("SLTU",
                          static_cast<std::uint8_t>(cpu_util::F3::SLTU)),
        bin<std::uint8_t>("XOR", static_cast<std::uint8_t>(cpu_util::F3::XOR)),
        bin<std::uint8_t>("OR", static_cast<std::uint8_t>(cpu_util::F3::OR)),
        bin<std::uint8_t>("AND", static_cast<std::uint8_t>(cpu_util::F3::AND)),
        bin<std::uint8_t>("SLL", static_cast<std::uint8_t>(cpu_util::F3::SLL)),
        bin<std::uint8_t>("SR", static_cast<std::uint8_t>(cpu_util::F3::SR))};

    COVERPOINT(std::uint8_t, addsub_cvp, f7_u,
               (opcode == cpu_util::Opcode::RR ||
                opcode == cpu_util::Opcode::RI) &&
                   f3 == cpu_util::F3::ADDSUB){
        bin<std::uint8_t>("ADD", static_cast<std::uint8_t>(cpu_util::F7::ADD)),
        bin<std::uint8_t>("SUB", static_cast<std::uint8_t>(cpu_util::F7::SUB))};

    COVERPOINT(std::uint8_t, sr_cvp, f7_u,
               (opcode == cpu_util::Opcode::RR ||
                opcode == cpu_util::Opcode::RI) &&
                   f3 == cpu_util::F3::SR){
        bin<std::uint8_t>("SRL", static_cast<std::uint8_t>(cpu_util::F7::SRL)),
        bin<std::uint8_t>("SRA", static_cast<std::uint8_t>(cpu_util::F7::SRA))};
};

class cpu_coverage_subscriber : public uvm::uvm_subscriber<cpu_seq_item> {

  public:
    UVM_COMPONENT_UTILS(cpu_coverage_subscriber);

    cpu_covergroup cg;

    cpu_coverage_subscriber(uvm::uvm_component_name name)
        : uvm::uvm_subscriber<cpu_seq_item>(name) {}

    virtual void write(const cpu_seq_item &i) {
        cpu_seq_item item = i;
        cg.sample(item);
    }
};

#endif
