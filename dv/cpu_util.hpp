#ifndef CPU_UTIL
#define CPU_UTIL

#include "cpu_seq_item.hpp"
#include <cstdint>
#include <sstream>
namespace cpu_util {

enum class Opcode {
    LUI = 0b0110111,
    AUIPC = 0b0010111,
    JAL = 0b1101111,
    JALR = 0b1100111,
    B = 0b1100011,
    L = 0b0000011,
    S = 0b0100011,
    RI = 0b0010011,
    RR = 0b0110011,
    F = 0b0001111,
    E = 0b1110011,
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

    // don't care
    X = 0
};

enum class F7 { ADD = 0b0, SUB = 0b0100000, SRL = 0b0, SRA = 0b0100000, X = 0 };

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

bool is_nop(cpu_seq_item &item);

void print_instruction(const cpu_seq_item &item, std::ostringstream &str);

} // namespace cpu_util

#endif
