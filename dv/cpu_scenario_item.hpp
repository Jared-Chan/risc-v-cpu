#ifndef CPU_SEN_ITEM_H
#define CPU_SEN_ITEM_H

#include "cpu_seq_item.hpp"
#include "cpu_util.hpp"

#include "crave/experimental/Constraint.hpp"
#include "crave/experimental/Object.hpp"
#include "crave/experimental/Variable.hpp"
#include "crave/frontend/Operators.hpp"
#include "uvm_randomized_sequence_item.h"
#include "uvmsc/base/uvm_object_globals.h"
#include "uvmsc/macros/uvm_message_defines.h"
#include "uvmsc/macros/uvm_object_defines.h"
#include <crave2uvm.h>
#include <systemc>
#include <uvm>

#include <cstdint>
#include <queue>
#include <sstream>

// random enum doesn't work properly yet
static std::uint8_t u8_opcodes[9] = {
    static_cast<std::uint8_t>(cpu_util::Opcode::LUI),
    static_cast<std::uint8_t>(cpu_util::Opcode::AUIPC),
    static_cast<std::uint8_t>(cpu_util::Opcode::JAL),
    static_cast<std::uint8_t>(cpu_util::Opcode::JALR),
    static_cast<std::uint8_t>(cpu_util::Opcode::B),
    static_cast<std::uint8_t>(cpu_util::Opcode::L),
    static_cast<std::uint8_t>(cpu_util::Opcode::S),
    static_cast<std::uint8_t>(cpu_util::Opcode::RI),
    static_cast<std::uint8_t>(cpu_util::Opcode::RR),
    /*static_cast<std::uint8_t>(cpu_util::Opcode::F),*/
    /*static_cast<std::uint8_t>(cpu_util::Opcode::SYS)*/
};

static std::uint8_t u8_f7[5] = {
    static_cast<std::uint8_t>(cpu_util::F7::ADD),
    static_cast<std::uint8_t>(cpu_util::F7::SUB),
    static_cast<std::uint8_t>(cpu_util::F7::SRL),
    static_cast<std::uint8_t>(cpu_util::F7::SRA),
    /*static_cast<std::uint8_t>(cpu_util::F7::X)*/
};

static std::uint8_t u8_f3_b[6] = {
    static_cast<std::uint8_t>(cpu_util::F3::BEQ),
    static_cast<std::uint8_t>(cpu_util::F3::BNE),
    static_cast<std::uint8_t>(cpu_util::F3::BLT),
    static_cast<std::uint8_t>(cpu_util::F3::BGE),
    static_cast<std::uint8_t>(cpu_util::F3::BLTU),
    static_cast<std::uint8_t>(cpu_util::F3::BGEU),
};

static std::uint8_t u8_f3_l[5] = {
    static_cast<std::uint8_t>(cpu_util::F3::LB),
    static_cast<std::uint8_t>(cpu_util::F3::LH),
    static_cast<std::uint8_t>(cpu_util::F3::LW),
    static_cast<std::uint8_t>(cpu_util::F3::LBU),
    static_cast<std::uint8_t>(cpu_util::F3::LHU),
};
static std::uint8_t u8_f3_s[3] = {
    static_cast<std::uint8_t>(cpu_util::F3::SB),
    static_cast<std::uint8_t>(cpu_util::F3::SH),
    static_cast<std::uint8_t>(cpu_util::F3::SW),
};
static std::uint8_t u8_f3_alu[8] = {
    static_cast<std::uint8_t>(cpu_util::F3::ADDSUB),
    static_cast<std::uint8_t>(cpu_util::F3::SLT),
    static_cast<std::uint8_t>(cpu_util::F3::SLTU),
    static_cast<std::uint8_t>(cpu_util::F3::XOR),
    static_cast<std::uint8_t>(cpu_util::F3::OR),
    static_cast<std::uint8_t>(cpu_util::F3::AND),
    static_cast<std::uint8_t>(cpu_util::F3::SLL),
    static_cast<std::uint8_t>(cpu_util::F3::SR),
    /*static_cast<std::uint8_t>(cpu_util::F3::X),*/
};

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

    // contraints
    crave::crv_constraint c_opcode_range{crave::inside(r_opcode(), u8_opcodes)};

    // TODO remove
    /*crave::crv_constraint c_opcode_val{*/
    /*    r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::L)};*/
    /*crave::crv_constraint c_f3_val{*/
    /*    r_funct3() == static_cast<std::uint8_t>(cpu_util::F3::BLT)};*/
    /*crave::crv_constraint c_imm_val{r_imm() == 0x1fffe8};*/
    /*crave::crv_constraint c_rs1_val_val{r_rs1_val() == 0x101040a};*/
    /*crave::crv_constraint c_rs2_val_val{r_rs2_val() == 0x2000003};*/
    /*crave::crv_constraint c_rs1_val{r_rs1() == 0x7};*/
    /*crave::crv_constraint c_rs2_val{r_rs2() == 0x10};*/
    /*crave::crv_constraint c_rd_val{r_rd() == 0x2};*/
    // remove end

    crave::crv_constraint c_funct7_range{crave::inside(r_funct7(), u8_f7)};

    crave::crv_constraint c_funct3_alu_range{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::RI) ||
            r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::RR),
        crave::inside(r_funct3(), u8_f3_alu))};

    crave::crv_constraint c_funct3_b_range{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::B),
        crave::inside(r_funct3(), u8_f3_b))};

    crave::crv_constraint c_funct3_s_range{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::S),
        crave::inside(r_funct3(), u8_f3_s))};

    crave::crv_constraint c_funct3_l_range{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::L),
        crave::inside(r_funct3(), u8_f3_l))};

    crave::crv_constraint c_r1_range{r_rs1() > 0, r_rs1() < 32};
    crave::crv_constraint c_r2_range{r_rs2() > 0, r_rs2() < 32};
    crave::crv_constraint c_rd_range{r_rd() > 0, r_rd() < 32};

    crave::crv_constraint c_r_different{r_rd() != r_rs1(), r_rs1 != r_rs2(),
                                        r_rs2 != r_rd()};

    // Limit of JAL. Add AUIPC to setup to extend iaddr testing range
    crave::crv_constraint c_iaddr_range{r_iaddr() < 0x00100000};

    crave::crv_constraint c_iaddr_align{r_iaddr() % 4 == 0};

    crave::crv_constraint c_addr_align{r_addr() % 4 == 0};
    crave::crv_constraint c_l_addr_align{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::L),
        (r_rs1_val() + r_imm()) % 4 == 0 && (r_rs2_val() + r_imm()) % 4 == 0)};

    // If branch, then branch destination % 4 == 0
    crave::crv_constraint c_b_destination_align{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::B),
        r_imm() % 4 == 0)};

    // Limitation of TB, destination must be far away from test instruction
    // range
    crave::crv_constraint c_b_destination_val{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::B) &&
            ((r_imm() & 0x1000) == 0),
        (r_imm() & 0x1FFE) > 0x20)};

    crave::crv_constraint c_b_destination_val_signed{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::B) &&
            ((r_imm() & 0x1000) == 0x1000),
        ((r_imm() | 0xFFFFE000) < (0xFFFFFFFF - 0x20)))};

    // Limitation of TB, in order to enforce instruction access ordering
    crave::crv_constraint c_iaddr_start{r_iaddr() > 11};

    crave::crv_constraint c_jalr_iaddr_align{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::JALR),
        ((r_imm() + r_rs1_val()) % 4 == 0) &&
            ((r_imm() + r_rs2_val()) % 4 == 0))}; // if rs1 == rs2

    // J destination should not be among test instructions
    crave::crv_constraint c_jalr_iaddr_val{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::JALR) &&
            ((r_imm() & 0x800) == 0),
        (((r_imm() & 0xfff) + r_rs1_val()) > r_iaddr() + 0x20) &&
            (((r_imm() & 0xfff) + r_rs2_val()) > r_iaddr() + 0x20))};

    crave::crv_constraint c_jalr_iaddr_val_signed{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::JALR) &&
            ((r_imm() & 0x800) == 0x800),
        ((r_imm() | 0xfffff000) <
         0xFFFFFFFF - (r_iaddr() + 0x20) - r_rs1_val()) &&
            ((r_imm() | 0xfffff000) <
             0xFFFFFFFF - (r_iaddr() + 0x20) - r_rs2_val()))};

    crave::crv_constraint c_jal_iaddr_align{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::JAL),
        (r_imm() % 4 == 0))};

    crave::crv_constraint c_jal_iaddr_val{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::JAL) &&
            ((r_imm() & 0x100000) == 0),
        (r_imm() & 0x1FFFFF) > r_iaddr() + 0x20)};

    crave::crv_constraint c_jal_iaddr_val_signed{crave::if_then(
        r_opcode() == static_cast<std::uint8_t>(cpu_util::Opcode::JAL) &&
            ((r_imm() & 0x100000) == 0x100000),
        ((r_imm() | 0xFFE00000) < 0xFFFFFFFF - (r_iaddr() + 0x20)))};

    // 'Fix' known randomization issue with CRAVE
    crave::crv_constraint c_not_equal_to_prev{
        r_opcode() != r_opcode(crave::prev),
        r_funct7() != r_funct7(crave::prev),
        r_funct3() != r_funct3(crave::prev),
        r_rs1() != r_rs1(crave::prev),
        r_rs2() != r_rs2(crave::prev),
        r_rd() != r_rd(crave::prev),
        r_rs1_val() != r_rs1_val(crave::prev),
        r_rs2_val() != r_rs2_val(crave::prev),
        r_imm() != r_imm(crave::prev),
        r_data() != r_data(crave::prev),
        r_addr() != r_addr(crave::prev),
        r_iaddr() != r_iaddr(crave::prev)};

    // calculated value
    std::uint32_t rd_val;

    cpu_seq_item nop;

    bool error;
    int cycles;              // info on whether a test runs for too long
    bool checked_write;      // by design, there is only one store per test
    bool should_check_write; // no need to check rd for branch
    bool first_instruction;
    std::queue<std::uint32_t> instruction_addresses; // addr in order
    int num_instructions;

    // unknown address at test start, so first item is stored here, not in imem
    cpu_seq_item first_instruction_item;

    // instruction memory
    std::map<std::uint32_t, cpu_seq_item> imem;
    // data memory, also contains expected wdata and wr
    std::map<std::uint32_t, cpu_seq_item> dmem;

    std::ostringstream rand_result_str;

    void get_next_instruction(cpu_seq_item &next_item, cpu_seq_item &last_rsp) {

        ++cycles;
        if (cycles > num_instructions * 4) {
            error = true;
            std::ostringstream str;
            str << std::endl;
            str << "\x1B[31mERROR \033[0m";
            str << "Too many cycles. Stopping. " << std::endl;
            str << " error:               " << error << std::endl;
            str << " checked store:       " << checked_write << std::endl;
            str << " remaining addresses: " << instruction_addresses.size();
            str << "    " << std::hex << instruction_addresses.front();
            UVM_ERROR(this->get_name(), str.str());
            UVM_ERROR(this->get_name(), rand_result_str.str());
        }

        if (first_instruction) {
            first_instruction = false;
            next_item = first_instruction_item;
            return;
        }

        // access imem
        if (imem.count(last_rsp.iaddr) == 1) {
            next_item = imem[last_rsp.iaddr];

            std::ostringstream str;
            str << "Reading instr at mem " << std::hex << last_rsp.iaddr;
            str << " remaning " << instruction_addresses.size() - 1;
            UVM_INFO(this->get_name(), str.str(), uvm::UVM_DEBUG);
            // Remove instructions from queue in order
            if (instruction_addresses.size() > 0 &&
                last_rsp.iaddr == instruction_addresses.front()) {
                instruction_addresses.pop();
                if (instruction_addresses.empty()) {
                    UVM_INFO(this->get_name(), "All instructions executed. ",
                             uvm::UVM_MEDIUM);
                }
            }

        } else {
            next_item = nop;
        }

        // access dmem
        if (last_rsp.wr == 1) {
            if (dmem.count(last_rsp.addr) == 1) {
                // check
                if (last_rsp.wdata == dmem[last_rsp.addr].wdata) {
                    // this is fine
                    checked_write = true;
                    UVM_INFO(this->get_name(), "Store wdata correct.",
                             uvm::UVM_MEDIUM);
                } else {
                    error = true;
                    std::ostringstream str;
                    str << std::endl;
                    str << "\x1B[31mERROR \033[0m";
                    str << "Unexpected response: " << std::endl;
                    str << " wdata:          0x" << std::hex << last_rsp.wdata
                        << std::endl;
                    str << " expected wdata: 0x" << std::hex
                        << dmem[last_rsp.addr].wdata;
                    UVM_ERROR(this->get_name(), str.str());
                    UVM_ERROR(this->get_name(), rand_result_str.str());
                }
            } else {
                error = true;
                std::ostringstream str;
                str << std::endl;
                str << "\x1B[31mERROR \033[0m";
                str << "Unexpected response: " << std::endl;
                str << " wr:          0x" << std::hex << last_rsp.wr
                    << std::endl;
                str << " expected wr: 0x" << std::hex << dmem[last_rsp.addr].wr;
                UVM_ERROR(this->get_name(), str.str());
                UVM_ERROR(this->get_name(), rand_result_str.str());
            }
        } else if (dmem.count(last_rsp.addr) == 1) {
            // data read
            next_item.data = dmem[last_rsp.addr].data;
            std::ostringstream str;
            str << "Reading data at mem " << std::hex << last_rsp.addr;
            str << " val " << next_item.data;
            UVM_INFO(this->get_name(), str.str(), uvm::UVM_DEBUG);
        }
    }
    bool has_next_instruction() {
        // test should continue if
        //     - there is no error
        //     and
        //         - we haven't checked the STORE instruction but should check
        //         OR
        //         - DUT hasn't fetched all instructions
        return ((!error) && ((!checked_write && should_check_write) ||
                             (!instruction_addresses.empty())));
    }

    void generate_instructions() {
        /* Based on randomized fields, put
         * - into imem
         *     - instructions and inputs to DUT
         * - into dmem
         *     - data and expected output
         *
         */
        cycles = 0;
        error = false;
        checked_write = false;
        should_check_write = true;
        first_instruction = true;
        instruction_addresses = std::queue<std::uint32_t>{};
        imem = std::map<std::uint32_t, cpu_seq_item>{};
        dmem = std::map<std::uint32_t, cpu_seq_item>{};

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

        // cast to unsigned for printing
        rand_result_str.str(std::string());
        rand_result_str << std::hex << "randomized values: opcode: "
                        << static_cast<unsigned>(opcode)
                        << ", f7: " << static_cast<unsigned>(funct7)
                        << ", f3: " << static_cast<unsigned>(funct3)
                        << ", rd: " << static_cast<unsigned>(rd)
                        << ", rs1: " << static_cast<unsigned>(rs1)
                        << ", rs2: " << static_cast<unsigned>(rs2)
                        << ", rs1_val: " << rs1_val << ", rs2_val: " << rs2_val
                        << ", imm: " << imm << ", data: " << data
                        << ", addr: " << addr << ", iaddr: " << iaddr << ". \n";
        UVM_INFO(this->get_name(), rand_result_str.str(), uvm::UVM_HIGH);

        std::uint32_t cur_iaddr = 0;
        std::uint32_t next_iaddr;
        // JAL
        cpu_util::make_instruction(cpu_util::Opcode::JAL, cpu_util::F3::X,
                                   cpu_util::F7::X,
                                   0,         // rs1
                                   0,         // rs2
                                   0,         // rd
                                   iaddr,     // imm
                                   0,         // data
                                   0,         // rs1_val
                                   0,         // rs2_val
                                   0,         // addr
                                   cur_iaddr, // cur_iaddr
                                   imem, dmem,
                                   next_iaddr // next_iaddr
        );
        first_instruction_item = imem[0];
        imem[0] = nop; // iaddr 0 may be used by the test
        cur_iaddr = next_iaddr;
        instruction_addresses.push(cur_iaddr);
        std::ostringstream str;
        str.str(std::string());
        str << "Made JAL, next addr: " << std::hex << cur_iaddr;
        UVM_INFO(this->get_name(), str.str(), uvm::UVM_DEBUG);

        // setup registers
        // rs1
        // adjust rs1_val to account for the case when rs1_val[11] == 1,
        // rs1_val[11:0] will be sign-extended in ADDI, essentially adding
        // -4096, so we manually add 4096 in that case
        std::uint32_t rs1_val_adjusted =
            ((rs1_val >> 11) & 0x1) == 0 ? rs1_val : rs1_val + (0x1 << 12);
        cpu_util::make_instruction(cpu_util::Opcode::LUI, cpu_util::F3::X,
                                   cpu_util::F7::X,
                                   0,                // rs1
                                   0,                // rs2
                                   rs1,              // rd
                                   rs1_val_adjusted, // imm
                                   0,                // data
                                   0,                // rs1_val
                                   0,                // rs2_val
                                   0,                // addr
                                   cur_iaddr,        // cur_iaddr
                                   imem, dmem,
                                   next_iaddr // next_iaddr
        );
        cur_iaddr = next_iaddr;
        instruction_addresses.push(cur_iaddr);
        str.str(std::string());
        str << "Made LUI 1, next addr: " << std::hex << cur_iaddr;
        UVM_INFO(this->get_name(), str.str(), uvm::UVM_DEBUG);

        cpu_util::make_instruction(cpu_util::Opcode::RI, cpu_util::F3::ADDSUB,
                                   cpu_util::F7::ADD,
                                   rs1,              // rs1
                                   0,                // rs2
                                   rs1,              // rd
                                   rs1_val_adjusted, // imm
                                   0,                // data
                                   0,                // rs1_val
                                   0,                // rs2_val
                                   0,                // addr
                                   cur_iaddr,        // cur_iaddr
                                   imem, dmem,
                                   next_iaddr // next_iaddr
        );
        cur_iaddr = next_iaddr;
        instruction_addresses.push(cur_iaddr);
        str.str(std::string());
        str << "Made RI 1, next addr: " << std::hex << cur_iaddr;
        UVM_INFO(this->get_name(), str.str(), uvm::UVM_DEBUG);

        // rs2
        std::uint32_t rs2_val_adjusted =
            ((rs2_val >> 11) & 0x1) == 0 ? rs2_val : rs2_val + (0x1 << 12);
        cpu_util::make_instruction(cpu_util::Opcode::LUI, cpu_util::F3::X,
                                   cpu_util::F7::X,
                                   0,                // rs1
                                   0,                // rs2
                                   rs2,              // rd
                                   rs2_val_adjusted, // imm
                                   0,                // data
                                   0,                // rs1_val
                                   0,                // rs2_val
                                   0,                // addr
                                   cur_iaddr,        // cur_iaddr
                                   imem, dmem,
                                   next_iaddr // next_iaddr
        );
        cur_iaddr = next_iaddr;
        instruction_addresses.push(cur_iaddr);
        str.str(std::string());
        str << "Made LUI 2, next addr: " << std::hex << cur_iaddr;
        UVM_INFO(this->get_name(), str.str(), uvm::UVM_DEBUG);

        cpu_util::make_instruction(cpu_util::Opcode::RI, cpu_util::F3::ADDSUB,
                                   cpu_util::F7::ADD,
                                   rs2,              // rs1
                                   0,                // rs2
                                   rs2,              // rd
                                   rs2_val_adjusted, // imm
                                   0,                // data
                                   0,                // rs1_val
                                   0,                // rs2_val
                                   0,                // addr
                                   cur_iaddr,        // cur_iaddr
                                   imem, dmem,
                                   next_iaddr // next_iaddr
        );
        cur_iaddr = next_iaddr;
        instruction_addresses.push(cur_iaddr);
        str.str(std::string());
        str << "Made RI 2, next addr: " << std::hex << cur_iaddr;
        UVM_INFO(this->get_name(), str.str(), uvm::UVM_DEBUG);
        // register setup finished

        // if rs1_val gets overwritten
        if (rs1 == rs2)
            rs1_val = rs2_val;

        // run randomized instruction
        std::uint32_t r_iaddr = cur_iaddr;
        cpu_util::make_instruction(opcode, funct3, funct7,
                                   rs1,       // rs1
                                   rs2,       // rs2
                                   rd,        // rd
                                   imm,       // imm
                                   data,      // data
                                   rs1_val,   // rs1_val
                                   rs2_val,   // rs2_val
                                   addr,      // addr
                                   cur_iaddr, // cur_iaddr
                                   imem, dmem,
                                   next_iaddr // next_iaddr
        );
        cur_iaddr = next_iaddr;
        instruction_addresses.push(cur_iaddr);
        str.str(std::string());
        str << "Made TEST instr " << static_cast<std::uint32_t>(opcode)
            << ", next addr: " << std::hex << cur_iaddr;
        UVM_INFO(this->get_name(), str.str(), uvm::UVM_DEBUG);

        // check
        std::uint32_t imm_sign_extended;
        imm_sign_extended = imm & 0xFFF;
        imm_sign_extended |=
            ((imm_sign_extended >> 11) & 1) == 0 ? 0 : 0xFFFFF000;
        std::uint32_t imm_shamt;
        bool rs1_sign_bit;

        // calculate expected rd value
        switch (opcode) {
        case (cpu_util::Opcode::JAL):
        case (cpu_util::Opcode::JALR):
            rd_val = r_iaddr + 4;
            break;
        case (cpu_util::Opcode::RI):
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
                if (funct7 == cpu_util::F7::SRA && ((rs1_val >> 31 & 1) == 1) &&
                    imm_shamt > 0)
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
                if (rs2_val >= 32)
                    rd_val = 0;
                else
                    rd_val = rs1_val << rs2_val;
                break;
            case (cpu_util::F3::SR):
                if (funct7 == cpu_util::F7::SRA && ((rs1_val >> 31 & 1) == 1)) {
                    if (rs2_val >= 32)
                        rd_val = 0xFFFFFFFF;
                    else if (rs2_val == 0)
                        rd_val = rs1_val;
                    else {
                        rd_val = rs1_val >> rs2_val;
                        rd_val |= (0xFFFFFFFF >> (32 - rs2_val))
                                  << (32 - rs2_val);
                    }
                } else {
                    if (rs2_val >= 32)
                        rd_val = 0;
                    else if (rs2_val == 0)
                        rd_val = rs1_val;
                    else
                        rd_val = rs1_val >> rs2_val;
                }
                str.str(std::string());
                str << "SR rs1_val" << std::hex << rs1_val
                    << ", rs2_val: " << std::hex << rs2_val
                    << ", rd_val: " << std::hex << rd_val;
                UVM_INFO(this->get_name(), str.str(), uvm::UVM_DEBUG);
                break;
            }
            break;
        case (cpu_util::Opcode::LUI):
            rd_val = imm & 0xFFFFF000;
            break;
        case (cpu_util::Opcode::AUIPC):
            rd_val = r_iaddr + (imm & 0xFFFFF000);
            break;
        case (cpu_util::Opcode::L):
            switch (funct3) {
            case (cpu_util::F3::LW):
                rd_val = data;
                break;
            case (cpu_util::F3::LH):
                rd_val = data & 0x0000FFFF;
                if ((data & 0x00008000) == 0x00008000)
                    rd_val |= 0xFFFF0000;
                break;
            case (cpu_util::F3::LB):
                rd_val = data & 0x000000FF;
                if ((data & 0x00000080) == 0x00000080)
                    rd_val |= 0xFFFFFF00;
                break;
            case (cpu_util::F3::LHU):
                rd_val = data & 0x0000FFFF;
                break;
            case (cpu_util::F3::LBU):
                rd_val = data & 0x000000FF;
                break;
            default:
                break;
            }
            break;

        // no rd
        case (cpu_util::Opcode::B):
        case (cpu_util::Opcode::S):
        case (cpu_util::Opcode::F):
        case (cpu_util::Opcode::SYS):
        default:
            break;
        }

        cpu_seq_item check_item{nop};
        std::uint32_t check_store_imm = 0;
        switch (opcode) {
        // check rd
        case (cpu_util::Opcode::JAL):
        case (cpu_util::Opcode::JALR):
        case (cpu_util::Opcode::RI):
        case (cpu_util::Opcode::RR):
        case (cpu_util::Opcode::LUI):
        case (cpu_util::Opcode::AUIPC):
        case (cpu_util::Opcode::L):
            // Do not overwrite dmem[rs1_val+imm_sign_extended]
            if (rs1_val + imm_sign_extended == check_store_imm)
                check_store_imm += 4;
            cpu_util::make_instruction(cpu_util::Opcode::S, cpu_util::F3::SW,
                                       cpu_util::F7::X,
                                       0,               // rs1
                                       rd,              // rs2
                                       0,               // rd
                                       check_store_imm, // imm
                                       0,               // data
                                       0,               // rs1_val
                                       rd_val,          // rs2_val
                                       0,               // addr
                                       cur_iaddr,       // cur_iaddr
                                       imem, dmem,
                                       next_iaddr // next_iaddr
            );
            cur_iaddr = next_iaddr;
            instruction_addresses.push(cur_iaddr);
            imem[cur_iaddr] = check_item; // check next iaddr
            str.str(std::string());
            str << "Made Store, next addr: " << std::hex << cur_iaddr;
            UVM_INFO(this->get_name(), str.str(), uvm::UVM_DEBUG);
            break;

        // check correct branched address
        case (cpu_util::Opcode::B):
            imem[cur_iaddr] = check_item;
            // Extra 2 cycles so the DUT works properly at the start of the next
            // test due to a case were branch destination is the same as the
            // second or third address of the next test, and so some
            // instructions are not executed
            imem[cur_iaddr + 4] = check_item;
            imem[cur_iaddr + 8] = check_item;
            instruction_addresses.push(cur_iaddr + 4);
            instruction_addresses.push(cur_iaddr + 8);
            should_check_write = false;
            break;

        // check next address
        case (cpu_util::Opcode::S):
            imem[cur_iaddr] = check_item;
            break;

        // no checking implemented yet
        case (cpu_util::Opcode::F):
        case (cpu_util::Opcode::SYS):
        default:
            should_check_write = false;
            break;
        }

        num_instructions = instruction_addresses.size();
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
