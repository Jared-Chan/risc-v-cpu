#ifndef CPU_UTIL_H
#define CPU_UTIL_H

#include "cpu_seq_item.hpp"

#include <cstdint>
#include <sstream>

#define CPU_ADDR_MASK 0x3FFFFFFF

namespace cpu_util {

enum class Opcode {
    LUI = 0b0110111,   // 37
    AUIPC = 0b0010111, // 17
    JAL = 0b1101111,   // 6f
    JALR = 0b1100111,  // 67
    B = 0b1100011,     // 63
    L = 0b0000011,     // 3
    S = 0b0100011,     // 23
    RI = 0b0010011,    // 13
    RR = 0b0110011,    // 33
    F = 0b0001111,     // 0f
    SYS = 0b1110011,   // c3
};

enum class F3 {

    // branch
    BEQ = 0b000,
    BNE = 0b001,
    BLT = 0b100,
    BGE = 0b101,
    BLTU = 0b110,
    BGEU = 0b111,
    // load
    LB = 0b000,
    LH = 0b001,
    LW = 0b010,
    LBU = 0b100,
    LHU = 0b101,
    // store
    SB = 0b000,
    SH = 0b001,
    SW = 0b010,
    // alu
    ADDSUB = 0b000,
    SLT = 0b010,
    SLTU = 0b011,
    XOR = 0b100,
    OR = 0b110,
    AND = 0b111,
    SLL = 0b001,
    SR = 0b101,

    CSRRW = 0b001,
    CSRRS = 0b010,
    CSRRC = 0b011,
    CSRRWI = 0b101,
    CSRRSI = 0b110,
    CSRRCI = 0b111,

    PRIV = 0b000,

    // don't care
    X = 0
};

enum class F7 { ADD = 0b0, SUB = 0b0100000, SRL = 0b0, SRA = 0b0100000, X = 0 };

enum class F12 { ECALL = 0b0, EBREAK = 0b1, X = 0 };

void make_unit_test(

    // Input: instruction under testing
    cpu_util::Opcode &opcode, cpu_util::F7 &funct7, cpu_util::F3 &funct3,
    std::uint8_t &rs1, std::uint8_t &rs2, std::uint8_t &rd,
    std::uint32_t &rs1_val, std::uint32_t &rs2_val, std::uint32_t &imm,
    std::uint32_t &data, std::uint32_t &addr, std::uint32_t &iaddr,
    cpu_seq_item &nop,

    // Output: unit test properties
    bool &should_check_write, bool &should_check_csr_cycle_instret_store,
    std::queue<std::uint32_t> &instruction_addresses,
    std::map<std::uint32_t, cpu_seq_item> &imem,
    std::map<std::uint32_t, cpu_seq_item> &dmem);

void make_instruction(Opcode opcode, F3 f3, F7 f7, std::uint8_t rs1,
                      std::uint8_t rs2, std::uint8_t rd, std::uint32_t imm,

                      std::uint32_t data, // LOAD/STORE
                      std::uint32_t rs1_val, std::uint32_t rs2_val,
                      std::uint32_t addr, // LOAD/STORE
                      std::uint32_t cur_iaddr,
                      // mock memory
                      std::map<std::uint32_t, cpu_seq_item> &imem,
                      std::map<std::uint32_t, cpu_seq_item> &dmem,
                      std::uint32_t &next_iaddr);

std::uint32_t make_j_type_instruction(Opcode opcode, std::uint8_t rd,
                                      std::uint32_t imm);
std::uint32_t make_u_type_instruction(Opcode opcode, std::uint8_t rd,
                                      std::uint32_t imm);
std::uint32_t make_i_type_instruction(Opcode opcode, F3 f3, std::uint8_t rd,
                                      std::uint32_t imm, std::uint8_t rs1);
std::uint32_t make_i_type_shift_instruction(Opcode opcode, F3 f3, F7 f7,
                                            std::uint8_t rd, std::uint32_t imm,
                                            std::uint8_t rs1);
std::uint32_t make_r_type_instruction(Opcode opcode, F3 f3, F7 f7,
                                      std::uint8_t rd, std::uint8_t rs1,
                                      std::uint8_t rs2);
std::uint32_t make_s_type_instruction(Opcode opcode, F3 f3, std::uint8_t rs1,
                                      std::uint8_t rs2, std::uint32_t imm);
std::uint32_t make_b_type_instruction(Opcode opcode, F3 f3, std::uint8_t rs1,
                                      std::uint8_t rs2, std::uint32_t imm);
std::uint32_t make_csr_instruction(Opcode opcode, F3 f3, std::uint8_t rd,
                                   std::uint32_t csr_src_dest,
                                   std::uint8_t rs1_imm);

bool is_nop(cpu_seq_item &item);
void decode_idata(cpu_seq_item &item, Opcode &opcode, F3 &f3, F7 &f7,
                  std::uint8_t &rs1, std::uint8_t &rs2, std::uint8_t &rd,
                  std::uint32_t &i_imm, std::uint32_t &s_imm,
                  std::uint32_t &u_imm, std::uint32_t &b_imm,
                  std::uint32_t &j_imm);

void print_instruction(const cpu_seq_item &item, std::ostringstream &str);

} // namespace cpu_util

#endif
