#ifndef CPU_SEN_ITEM
#define CPU_SEN_ITEM

#include "cpu_seq_item.hpp"
#include "cpu_util.hpp"
#include "uvmsc/macros/uvm_object_defines.h"
#include <cstdint>
#include <queue>
#include <systemc>
#include <utility>
#include <uvm>

// Transaction object used by sequences to generate cpu_seq_item
class cpu_scenario_item : public uvm::uvm_sequence_item {
  public:
    cpu_scenario_item(const std::string &name = "cpu_scenario_item")
        : uvm::uvm_sequence_item(name) {
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
    cpu_util::Opcode opcode;
    cpu_util::F7 funct7;
    cpu_util::F3 funct3;
    std::uint8_t rs1;
    std::uint8_t rs2;
    std::uint8_t rd;
    std::uint32_t rs1_val;
    std::uint32_t rs2_val;
    std::uint32_t imm;
    std::uint32_t data;
    std::uint32_t addr;
    std::uint32_t iaddr;

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
        opcode = rhs_->opcode;
        funct7 = rhs_->funct7;
        funct3 = rhs_->funct3;
        rs1 = rhs_->rs1;
        rs2 = rhs_->rs2;
        rd = rhs_->rd;
        imm = rhs_->imm;
    }

    virtual bool do_compare(const uvm::uvm_object *rhs) const {
        const cpu_scenario_item *rhs_ =
            dynamic_cast<const cpu_scenario_item *>(rhs);
        return (opcode == rhs_->opcode && funct7 == rhs_->funct7 &&
                funct3 == rhs_->funct3 && rs1 == rhs_->rs1 &&
                rs2 == rhs_->rs2 && rd == rhs_->rd && imm == rhs_->imm);
    }
};

#endif
