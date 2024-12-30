#ifndef CPU_SEN_ITEM
#define CPU_SEN_ITEM

#include "cpu_seq_item.hpp"
#include "cpu_util.hpp"
#include "crave/experimental/Constraint.hpp"
#include "crave/experimental/Object.hpp"
#include "crave/experimental/Variable.hpp"
#include "uvm_randomized_sequence_item.h"
#include "uvmsc/macros/uvm_object_defines.h"
#include <crave2uvm.h>
#include <cstdint>
#include <queue>
#include <systemc>
#include <utility>
#include <uvm>

// Transaction object used by sequences to generate cpu_seq_item
class cpu_scenario_item : public uvm_randomized_sequence_item {
  public:
    cpu_scenario_item(crave::crv_object_name name = "cpu_scenario_item")
        : uvm_randomized_sequence_item(name) {
        nop.idata = cpu_util::make_i_type_instruction(
            cpu_util::Opcode::RI, cpu_util::F3::ADDSUB, 0, 0, 0);
        nop.data = 0;
        nop.rst_n = true;
        nop.iaddr = 0;
        nop.addr = 0;
        nop.wr = false;
        nop.wdata = 0;
    }

    ~cpu_scenario_item() {}

    UVM_OBJECT_UTILS(cpu_scenario_item);

    // randomized values
    crave::crv_variable<std::uint8_t> r_opcode;
    crave::crv_variable<std::uint8_t> r_funct7;
    crave::crv_variable<std::uint8_t> r_funct3;
    crave::crv_variable<std::uint8_t> r_rs1;
    crave::crv_variable<std::uint8_t> r_rs2;
    crave::crv_variable<std::uint8_t> r_rd;
    crave::crv_variable<std::uint32_t> r_rs1_val;
    crave::crv_variable<std::uint32_t> r_rs2_val;
    crave::crv_variable<std::uint32_t> r_imm;
    crave::crv_variable<std::uint32_t> r_data;
    crave::crv_variable<std::uint32_t> r_addr;
    crave::crv_variable<std::uint32_t> r_iaddr;

    crave::crv_constraint opcode_range{crave::inside(
        r_opcode(),
        // copied from cpu_util.hpp
        // random enum doesn't work properly yet
        std::set<std::uint8_t>{0b0110111, 0b0010111, 0b1101111, 0b1100111,
                               0b1100011, 0b0000011, 0b0100011, 0b0010011,
                               0b0110011, 0b0001111, 0b1110011})};

    crave::crv_constraint funct7_range{crave::inside(
        r_funct7(), std::set<std::uint8_t>{0b0, 0b0100000, 0b0, 0b0100000, 0})};

    crave::crv_constraint funct3_range{crave::inside(
        r_funct3(), std::set<std::uint8_t>{
                        0b000, 0b001, 0b100, 0b101, 0b110, 0b111, 0b000, 0b001,
                        0b010, 0b100, 0b101, 0b000, 0b001, 0b010, 0b000, 0b010,
                        0b011, 0b100, 0b110, 0b111, 0b001, 0b101, 0})};

    crave::crv_constraint reg_range{r_rs1() < 32 && r_rs2() < 32 &&
                                    r_rd() < 32};

    // calculated values
    std::uint32_t rd_val;

    cpu_seq_item nop;

    std::queue<std::pair<cpu_seq_item, cpu_seq_item>> instructions;

    void get_next_instruction(cpu_seq_item &instruction,
                              cpu_seq_item &expected) {

        std::pair<cpu_seq_item, cpu_seq_item> pair = instructions.front();
        cpu_seq_item next_instruction = pair.first;
        cpu_seq_item next_expected = pair.second;

        instruction = next_instruction;
        expected = next_expected;

        instructions.pop();
    }
    bool has_next_instruction() { return (!instructions.empty()); }

    void generate_instructions() {
        /* Based on randomized fields, generate pairs of cpu_seq_items and
         * expected results.
         * instructions = {
         *      <i1, exp0>,
         *      <i2, exp1>,
         *      ...
         * }
         * Each instruction is paired with the last expected results because
         * after each positive edge of the clock, the current instruction is
         * registered in while the last action is registered out.
         *
         */

        r_opcode.randomize();
        r_opcode.randomize();
        r_opcode.randomize();
        r_rs1.randomize();
        r_rs1.randomize();

        cpu_util::Opcode opcode{static_cast<cpu_util::Opcode>(r_opcode.get())};
        cpu_util::F7 funct7{static_cast<cpu_util::F7>(r_funct7.get())};
        cpu_util::F3 funct3{static_cast<cpu_util::F3>(r_funct3.get())};
        std::uint8_t rs1{r_rs1.get()};
        std::uint8_t rs2{r_rs2.get()};
        std::uint8_t rd{r_rd.get()};
        std::uint32_t rs1_val{r_rs1_val.get()};
        std::uint32_t rs2_val{r_rs2_val.get()};
        std::uint32_t imm{r_imm.get()};
        std::uint32_t data{r_data.get()};
        std::uint32_t addr{r_addr.get()};
        std::uint32_t iaddr{r_iaddr.get()};

        // JAL
        cpu_seq_item jal, jal_exp;
        cpu_util::make_instruction(cpu_util::Opcode::JAL, cpu_util::F3::X,
                                   cpu_util::F7::X,
                                   0,     // rs1
                                   0,     // rs2
                                   5,     // rd
                                   iaddr, // imm
                                   0,     // data
                                   0,     // rs1_val
                                   0,     // rs2_val
                                   0,     // addr
                                   0,     // cur_iaddr
                                   jal, jal_exp);
        std::pair<cpu_seq_item, cpu_seq_item> p{jal, nop};
        instructions.push(p);

        // setup registers
        // rs1
        cpu_seq_item s11, s11_exp;
        cpu_util::make_instruction(cpu_util::Opcode::LUI, cpu_util::F3::X,
                                   cpu_util::F7::X,
                                   0,       // rs1
                                   0,       // rs2
                                   rs1,     // rd
                                   rs1_val, // imm
                                   0,       // data
                                   0,       // rs1_val
                                   0,       // rs2_val
                                   0,       // addr
                                   iaddr,   // cur_iaddr
                                   s11, s11_exp);
        std::pair<cpu_seq_item, cpu_seq_item> s11_p{s11, jal_exp};
        instructions.push(s11_p);
        cpu_seq_item s12, s12_exp;
        cpu_util::make_instruction(cpu_util::Opcode::RI, cpu_util::F3::ADDSUB,
                                   cpu_util::F7::ADD,
                                   0,         // rs1
                                   0,         // rs2
                                   rs1,       // rd
                                   rs1_val,   // imm
                                   0,         // data
                                   0,         // rs1_val
                                   0,         // rs2_val
                                   0,         // addr
                                   iaddr + 4, // cur_iaddr
                                   s12, s12_exp);
        std::pair<cpu_seq_item, cpu_seq_item> s12_p{s12, s11_exp};
        instructions.push(s12_p);
        // rs2
        cpu_seq_item s21, s21_exp;
        cpu_util::make_instruction(cpu_util::Opcode::LUI, cpu_util::F3::X,
                                   cpu_util::F7::X,
                                   0,         // rs1
                                   0,         // rs2
                                   rs2,       // rd
                                   rs2_val,   // imm
                                   0,         // data
                                   0,         // rs1_val
                                   0,         // rs2_val
                                   0,         // addr
                                   iaddr + 8, // cur_iaddr
                                   s21, s21_exp);
        std::pair<cpu_seq_item, cpu_seq_item> s21_p{s21, s12_exp};
        instructions.push(s21_p);
        cpu_seq_item s22, s22_exp;
        cpu_util::make_instruction(cpu_util::Opcode::RI, cpu_util::F3::ADDSUB,
                                   cpu_util::F7::ADD,
                                   0,          // rs1
                                   0,          // rs2
                                   rs2,        // rd
                                   rs2_val,    // imm
                                   0,          // data
                                   0,          // rs1_val
                                   0,          // rs2_val
                                   0,          // addr
                                   iaddr + 12, // cur_iaddr
                                   s22, s22_exp);
        std::pair<cpu_seq_item, cpu_seq_item> s22_p{s22, s21_exp};
        instructions.push(s22_p);
        // register setup finished

        // run randomized instruction
        cpu_seq_item r, r_exp;
        cpu_util::make_instruction(opcode, funct3, funct7,
                                   rs1,        // rs1
                                   rs2,        // rs2
                                   rd,         // rd
                                   imm,        // imm
                                   data,       // data
                                   rs1_val,    // rs1_val
                                   rs2_val,    // rs2_val
                                   addr,       // addr
                                   iaddr + 16, // cur_iaddr
                                   r, r_exp);
        std::pair<cpu_seq_item, cpu_seq_item> r_p{r, s22_exp};
        instructions.push(r_p);
        if (opcode == cpu_util::Opcode::L || opcode == cpu_util::Opcode::S) {
            // TODO set iaddr (and check in sequence)
            std::pair<cpu_seq_item, cpu_seq_item> r_p2{nop, nop};
            instructions.push(r_p2);
        }

        // check
        std::uint32_t imm_sign_extended;
        std::uint32_t imm_shamt;
        bool rs1_sign_bit;
        switch (opcode) {
        // calculate expected rd value
        case (cpu_util::Opcode::JAL):
        case (cpu_util::Opcode::JALR):
            rd_val = iaddr + 20;
            break;
        case (cpu_util::Opcode::RI):
            imm_sign_extended = imm & 0xFFF;
            imm_sign_extended |=
                ((imm_sign_extended >> 11) & 1) == 0 ? 0 : 0xFFFFF000;
            imm_shamt = imm & 0x1F;
            rs1_sign_bit = rs1_val >> 31;
            switch (funct3) {
            case (cpu_util::F3::ADDSUB):
                rd_val = rs1_val + imm_sign_extended;
                break;
            case (cpu_util::F3::SLT):
                rd_val = static_cast<int>(rs1_val) <
                                 static_cast<int>(imm_sign_extended)
                             ? 1
                             : 0;
                break;
            case (cpu_util::F3::SLTU):
                rd_val = rs1_val < imm_sign_extended ? 1 : 0;
                break;
            case (cpu_util::F3::AND):
                rd_val = rs1_val & imm_sign_extended;
                break;
            case (cpu_util::F3::OR):
                rd_val = rs1_val | imm_sign_extended;
                break;
            case (cpu_util::F3::XOR):
                rd_val = rs1_val ^ imm_sign_extended;
                break;
            case (cpu_util::F3::SLL):
                rd_val = rs1_val << imm_shamt;
                break;
            case (cpu_util::F3::SR):
                rd_val = rs1_val >> imm_shamt;
                if (funct7 == cpu_util::F7::SRA)
                    rd_val |= (0xFFFFFFFF >> (32 - imm_shamt))
                              << (32 - imm_shamt);
                break;
            }
            break;
        case (cpu_util::Opcode::RR):
            imm_shamt = rs2_val & 0x1F;
            rs1_sign_bit = rs1_val >> 31;
            switch (funct3) {
            case (cpu_util::F3::ADDSUB):
                if (funct7 == cpu_util::F7::ADD)
                    rd_val = rs1_val + rs2_val;
                else // if (funct7 == cpu_util::F7::SUB)
                    rd_val = rs1_val - rs2_val;
                break;
            case (cpu_util::F3::SLT):
                rd_val = static_cast<int>(rs1_val) < static_cast<int>(rs2_val)
                             ? 1
                             : 0;
                break;
            case (cpu_util::F3::SLTU):
                rd_val = rs1_val < rs2_val ? 1 : 0;
                break;
            case (cpu_util::F3::AND):
                rd_val = rs1_val & rs2_val;
                break;
            case (cpu_util::F3::OR):
                rd_val = rs1_val | rs2_val;
                break;
            case (cpu_util::F3::XOR):
                rd_val = rs1_val ^ rs2_val;
                break;
            case (cpu_util::F3::SLL):
                rd_val = rs1_val << rs2_val;
                break;
            case (cpu_util::F3::SR):
                rd_val = rs1_val >> rs2_val;
                if (funct7 == cpu_util::F7::SRA)
                    rd_val |= (0xFFFFFFFF >> (32 - imm_shamt))
                              << (32 - imm_shamt);
                break;
            }
            break;
        case (cpu_util::Opcode::LUI):
            rd_val = imm & 0xFFFFF000;
            break;
        case (cpu_util::Opcode::AUIPC):
            rd_val = iaddr + 16 + (imm & 0xFFFFF000);
            break;
        case (cpu_util::Opcode::L):
            rd_val = data;
            break;

        // no rd
        case (cpu_util::Opcode::B):
        case (cpu_util::Opcode::S):
        case (cpu_util::Opcode::F):
        case (cpu_util::Opcode::E):
        default:
            break;
        }

        cpu_seq_item c, c_exp;
        std::pair<cpu_seq_item, cpu_seq_item> c_p;
        std::pair<cpu_seq_item, cpu_seq_item> c_p2{nop, nop};
        std::pair<cpu_seq_item, cpu_seq_item> c_p3{nop, nop};
        switch (opcode) {
        // check rd
        case (cpu_util::Opcode::JAL):
        case (cpu_util::Opcode::JALR):
        case (cpu_util::Opcode::RI):
        case (cpu_util::Opcode::RR):
        case (cpu_util::Opcode::LUI):
        case (cpu_util::Opcode::AUIPC):
        case (cpu_util::Opcode::L):
            cpu_util::make_instruction(cpu_util::Opcode::S, cpu_util::F3::SW,
                                       cpu_util::F7::X,
                                       0,          // rs1
                                       rd,         // rs2
                                       0,          // rd
                                       0,          // imm
                                       rd_val,     // data
                                       0,          // rs1_val
                                       0,          // rs2_val
                                       0,          // addr
                                       iaddr + 20, // cur_iaddr
                                       c, c_exp);
            c_p = {c, r_exp};
            instructions.push(c_p);
            instructions.push(c_p2); // nop, nop
            c_p3 = {nop, c_exp};
            instructions.push(c_p3);
            break;

        // checking already done by expected cpu_seq_item
        case (cpu_util::Opcode::B):
        case (cpu_util::Opcode::S):

        // no checking implemented yet
        case (cpu_util::Opcode::F):
        case (cpu_util::Opcode::E):
        default:
            c_p = {nop, r_exp};
            instructions.push(c_p);
            break;
        }
    }

    virtual void do_print(uvm::uvm_printer &printer) const {}

    virtual void do_pack(uvm::uvm_packer &packer) const {}

    virtual void do_unpack(uvm::uvm_packer &packer) {}

    virtual void do_copy(const uvm::uvm_object *rhs) {
        const cpu_scenario_item *rhs_ =
            dynamic_cast<const cpu_scenario_item *>(rhs);
        r_opcode = rhs_->r_opcode;
        r_funct7 = rhs_->r_funct7;
        r_funct3 = rhs_->r_funct3;
        r_rs1 = rhs_->r_rs1;
        r_rs2 = rhs_->r_rs2;
        r_rs1_val = rhs_->r_rs1_val;
        r_rs2_val = rhs_->r_rs2_val;
        r_rd = rhs_->r_rd;
        r_imm = rhs_->r_imm;
    }

    virtual bool do_compare(const uvm::uvm_object *rhs) const {
        const cpu_scenario_item *rhs_ =
            dynamic_cast<const cpu_scenario_item *>(rhs);
        return (r_opcode == rhs_->r_opcode && r_funct7 == rhs_->r_funct7 &&
                r_funct3 == rhs_->r_funct3 && r_rs1 == rhs_->r_rs1 &&
                r_rs1_val == rhs_->r_rs1_val && r_rs2_val == rhs_->r_rs2_val &&
                r_rs2 == rhs_->r_rs2 && r_rd == rhs_->r_rd &&
                r_imm == rhs_->r_imm);
    }
};

#endif
