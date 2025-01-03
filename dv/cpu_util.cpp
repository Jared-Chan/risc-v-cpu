#include "cpu_util.hpp"
#include "cpu_seq_item.hpp"
#include <cstdint>

std::uint32_t cpu_util::make_j_type_instruction(cpu_util::Opcode opcode,
                                                std::uint8_t rd,
                                                std::uint32_t imm) {
    std::uint32_t idata = 0;
    idata |= static_cast<std::uint32_t>(opcode);
    idata |= (static_cast<std::uint32_t>(rd) << 7);
    idata |= (((imm & (1 << 20)) >> 20) << 31);
    idata |= (((imm >> 1) & 0x3ff) << 21);
    idata |= (((imm & (1 << 11)) >> 11) << 20);
    idata |= (((imm >> 12) & 0xff) << 12);
    return idata;
}

std::uint32_t cpu_util::make_u_type_instruction(cpu_util::Opcode opcode,
                                                std::uint8_t rd,
                                                std::uint32_t imm) {
    std::uint32_t idata = 0;
    idata |= static_cast<std::uint32_t>(opcode);
    idata |= (static_cast<std::uint32_t>(rd) << 7);
    idata |= (imm & 0xFFFFF000);
    return idata;
}

std::uint32_t cpu_util::make_i_type_instruction(cpu_util::Opcode opcode,
                                                cpu_util::F3 f3,
                                                std::uint8_t rd,
                                                std::uint32_t imm,
                                                std::uint8_t rs1) {

    std::uint32_t idata = 0;
    idata |= static_cast<std::uint32_t>(opcode);
    idata |= (static_cast<std::uint32_t>(rd) << 7);
    idata |= (static_cast<std::uint32_t>(f3) & 0x7) << 12;
    idata |= (static_cast<std::uint32_t>(rs1) << 15);
    idata |= (imm & 0xFFF) << 20;

    return idata;
}

std::uint32_t cpu_util::make_csr_instruction(cpu_util::Opcode opcode,
                                             cpu_util::F3 f3, std::uint8_t rd,
                                             std::uint32_t csr_src_dest,
                                             std::uint8_t rs1_imm) {

    std::uint32_t idata = 0;
    idata = cpu_util::make_i_type_instruction(
        opcode, f3, rd, csr_src_dest & 0xFFF, rs1_imm & 0x1F);
    return idata;
}

std::uint32_t cpu_util::make_i_type_shift_instruction(
    cpu_util::Opcode opcode, cpu_util::F3 f3, cpu_util::F7 f7, std::uint8_t rd,
    std::uint32_t imm, std::uint8_t rs1) {

    std::uint32_t idata = 0;
    idata |= static_cast<std::uint32_t>(opcode);
    idata |= (static_cast<std::uint32_t>(rd) << 7);
    idata |= (static_cast<std::uint32_t>(f3) & 0x7) << 12;
    idata |= (static_cast<std::uint32_t>(rs1) << 15);
    idata |= (imm & 0x1F) << 20;
    idata |= (static_cast<std::uint32_t>(f7) & 0x7F) << 25;

    return idata;
}

std::uint32_t
cpu_util::make_r_type_instruction(cpu_util::Opcode opcode, cpu_util::F3 f3,
                                  cpu_util::F7 f7, std::uint8_t rd,
                                  std::uint8_t rs1, std::uint8_t rs2) {

    std::uint32_t idata = 0;
    idata |= static_cast<std::uint32_t>(opcode);
    idata |= (static_cast<std::uint32_t>(rd) << 7);
    idata |= (static_cast<std::uint32_t>(f3) & 0x7) << 12;
    idata |= (static_cast<std::uint32_t>(rs1) << 15);
    idata |= (static_cast<std::uint32_t>(rs2) << 20);
    idata |= (static_cast<std::uint32_t>(f7) & 0x7F) << 25;
    return idata;
}

std::uint32_t cpu_util::make_s_type_instruction(cpu_util::Opcode opcode,
                                                cpu_util::F3 f3,
                                                std::uint8_t rs1,
                                                std::uint8_t rs2,
                                                std::uint32_t imm) {

    std::uint32_t idata = 0;
    idata |= static_cast<std::uint32_t>(opcode);
    idata |= ((static_cast<std::uint32_t>(imm) & 0x1F) << 7);
    idata |= (static_cast<std::uint32_t>(f3) & 0x7) << 12;
    idata |= (static_cast<std::uint32_t>(rs1) << 15);
    idata |= (static_cast<std::uint32_t>(rs2) << 20);
    idata |= ((imm & 0xFFF) >> 5) << 25;

    return idata;
}

std::uint32_t cpu_util::make_b_type_instruction(cpu_util::Opcode opcode,
                                                cpu_util::F3 f3,
                                                std::uint8_t rs1,
                                                std::uint8_t rs2,
                                                std::uint32_t imm) {

    std::uint32_t idata = 0;
    idata |= static_cast<std::uint32_t>(opcode);
    idata |= (((static_cast<std::uint32_t>(imm) >> 11) & 1) << 7);
    idata |= (((static_cast<std::uint32_t>(imm) >> 1) & 0xF) << 8);
    idata |= (static_cast<std::uint32_t>(f3) & 0x7) << 12;
    idata |= (static_cast<std::uint32_t>(rs1) << 15);
    idata |= (static_cast<std::uint32_t>(rs2) << 20);
    idata |= ((imm >> 5) & 0x3F) << 25;
    idata |= ((imm >> 12) & 0x1) << 31;

    return idata;
}

bool cpu_util::is_nop(cpu_seq_item &item) {

    if (item.idata == cpu_util::make_i_type_instruction(
                          cpu_util::Opcode::RI, cpu_util::F3::ADDSUB, 0, 0, 0))
        return true;
    return false;
}

void cpu_util::decode_idata(cpu_seq_item &item, Opcode &opcode, F3 &f3, F7 &f7,
                            std::uint8_t &rs1, std::uint8_t &rs2,
                            std::uint8_t &rd, std::uint32_t &i_imm,
                            std::uint32_t &s_imm, std::uint32_t &u_imm,
                            std::uint32_t &b_imm, std::uint32_t &j_imm) {
    opcode = static_cast<cpu_util::Opcode>(item.idata & 0x7F);
    f3 = static_cast<cpu_util::F3>((item.idata >> 12) & 0x7);
    f7 = static_cast<cpu_util::F7>(item.idata >> 25);
    rd = (item.idata >> 7) & 0x1F;
    rs1 = (item.idata >> 15) & 0x1F;
    rs2 = (item.idata >> 20) & 0x1F;
    i_imm = (item.idata >> 20) & 0xFFF;
    i_imm |= ((i_imm >> 11) & 0x1) == 0 ? 0 : (0xFFFFFFFF << 11);
    s_imm = ((item.idata >> 20) & 0xFE0) | ((item.idata >> 7) & 0x1F);
    s_imm |= ((s_imm >> 11) & 0x1) == 0 ? 0 : (0xFFFFFFFF << 11);
    b_imm = ((item.idata >> 20) & 0x7E0) | (((item.idata >> 31) & 0x1) << 12) |
            (((item.idata >> 8) & 0xF) << 1) |
            (((item.idata >> 7) & 0x1) << 11);
    b_imm |= ((b_imm >> 12) & 0x1) == 0 ? 0 : (0xFFFFFFFF << 12);
    u_imm = item.idata & 0xFFFFF000;
    j_imm = (((item.idata >> 21) & 0x3FF) << 1) |
            (((item.idata >> 31) & 0x1) << 20) |
            (((item.idata >> 12) & 0xFF) << 12) |
            (((item.idata >> 20) & 0x1) << 11);
    j_imm |= ((j_imm >> 20) & 0x1) == 0 ? 0 : (0xFFFFFFFF << 20);
}

void cpu_util::print_instruction(const cpu_seq_item &item,
                                 std::ostringstream &str) {

    str << "PC: 0x" << std::hex << item.iaddr << ", I: ";

    cpu_util::Opcode opcode;
    cpu_util::F3 f3;
    cpu_util::F7 f7;
    std::uint8_t riuj_rd;
    std::uint8_t risb_rs1;
    std::uint8_t rsb_rs2;

    std::uint32_t i_imm;
    std::uint32_t s_imm;
    std::uint32_t b_imm;
    std::uint32_t u_imm;
    std::uint32_t j_imm;

    cpu_seq_item _item = item;
    cpu_util::decode_idata(_item, opcode, f3, f7, risb_rs1, rsb_rs2, riuj_rd,
                           i_imm, s_imm, u_imm, b_imm, j_imm);

    std::uint32_t csr_src_dest = i_imm;

    switch (opcode) {
    case (cpu_util::Opcode::JAL):
        str << " JAL to " << std::hex << j_imm;
        str << " with rd 0x" << std::hex << static_cast<unsigned>(riuj_rd);
        break;
    case (cpu_util::Opcode::JALR):
        str << " JALR with offset 0x" << std::hex << i_imm;
        str << " and rs1 0x" << std::hex << static_cast<unsigned>(risb_rs1);
        str << " and rd 0x" << std::hex << static_cast<unsigned>(riuj_rd);
        break;
    case (cpu_util::Opcode::RI):
        str << " RI ";
        switch (f3) {
        case (cpu_util::F3::ADDSUB):
            str << " ADD ";
            break;
        case (cpu_util::F3::SLT):
            str << " SLT ";
            break;
        case (cpu_util::F3::SLTU):
            str << " SLTU ";
            break;
        case (cpu_util::F3::AND):
            str << " AND ";
            break;
        case (cpu_util::F3::OR):
            str << " OR ";
            break;
        case (cpu_util::F3::XOR):
            str << " XOR ";
            break;
        case (cpu_util::F3::SLL):
            str << " SLL ";
            break;
        case (cpu_util::F3::SR):
            if (f7 == cpu_util::F7::SRA)
                str << " SRA ";
            else
                str << " SRL ";
            break;
        }
        str << " with imm 0x" << std::hex << i_imm;
        str << " and rs1 0x" << std::hex << static_cast<unsigned>(risb_rs1);
        str << " and rd 0x" << std::hex << static_cast<unsigned>(riuj_rd);
        break;
    case (cpu_util::Opcode::RR):
        str << " RR ";
        switch (f3) {
        case (cpu_util::F3::ADDSUB):
            if (f7 == cpu_util::F7::ADD)
                str << " ADD " << std::hex << static_cast<unsigned>(riuj_rd);
            else
                str << " SUB " << std::hex << static_cast<unsigned>(riuj_rd);
        case (cpu_util::F3::SLT):
            str << " SLT ";
            break;
        case (cpu_util::F3::SLTU):
            str << " SLTU ";
            break;
        case (cpu_util::F3::AND):
            str << " AND ";
            break;
        case (cpu_util::F3::OR):
            str << " OR ";
            break;
        case (cpu_util::F3::XOR):
            str << " XOR ";
            break;
        case (cpu_util::F3::SLL):
            str << " SLL ";
            break;
        case (cpu_util::F3::SR):
            if (f7 == cpu_util::F7::SRA)
                str << " SRA ";
            else
                str << " SRL ";
            break;
        }
        str << " with rs1 0x" << std::hex << static_cast<unsigned>(risb_rs1);
        str << " and rs2 0x" << std::hex << static_cast<unsigned>(rsb_rs2);
        str << " and rd 0x" << std::hex << static_cast<unsigned>(riuj_rd);
        break;
    case (cpu_util::Opcode::LUI):
        str << " LUI ";
        str << " with imm 0x" << std::hex << u_imm;
        str << " and rd 0x" << std::hex << static_cast<unsigned>(riuj_rd);
        break;
    case (cpu_util::Opcode::AUIPC):
        str << " LUI ";
        str << " with imm 0x" << std::hex << u_imm;
        str << " and rd 0x" << std::hex << static_cast<unsigned>(riuj_rd);
        break;

    case (cpu_util::Opcode::L):
        str << " L ";
        str << " with imm 0x" << std::hex << i_imm;
        str << " with width 0x" << std::hex << static_cast<unsigned>(f3);
        str << " and rs1 0x" << std::hex << static_cast<unsigned>(risb_rs1);
        str << " and rd 0x" << std::hex << static_cast<unsigned>(riuj_rd);
        break;

    case (cpu_util::Opcode::S):
        str << " S ";
        str << " with imm 0x" << std::hex << s_imm;
        str << " with width 0x" << std::hex << static_cast<unsigned>(f3);
        str << " and rs1 0x" << std::hex << static_cast<unsigned>(risb_rs1);
        str << " and rs2 0x" << std::hex << static_cast<unsigned>(rsb_rs2);
        break;

    case (cpu_util::Opcode::B):
        str << " B ";
        switch (f3) {
        case (cpu_util::F3::BEQ):
            str << "BEQ ";
            break;
        case (cpu_util::F3::BNE):
            str << "BNE ";
            break;
        case (cpu_util::F3::BLT):
            str << "BLT ";
            break;
        case (cpu_util::F3::BGE):
            str << "BGE ";
            break;
        case (cpu_util::F3::BLTU):
            str << "BLTU ";
            break;
        case (cpu_util::F3::BGEU):
            str << "BGEU ";
            break;
        default:
            break;
        }
        str << " with imm 0x" << std::hex << b_imm;
        str << " and rs1 0x" << std::hex << static_cast<unsigned>(risb_rs1);
        str << " and rs2 0x" << std::hex << static_cast<unsigned>(rsb_rs2);
        break;

    // not implemented, set to NOP
    case (cpu_util::Opcode::F):
        str << " F ";
        break;
    case (cpu_util::Opcode::SYS):
        str << " SYS ";
        switch (f3) {
        case (cpu_util::F3::CSRRW):
            str << "CSRRW ";
            break;
        case (cpu_util::F3::CSRRS):
            str << "CSRRS ";
            break;
        case (cpu_util::F3::CSRRC):
            str << "CSRRC ";
            break;
        case (cpu_util::F3::CSRRWI):
            str << "CSRRWI ";
            break;
        case (cpu_util::F3::CSRRSI):
            str << "CSRRSI ";
            break;
        case (cpu_util::F3::CSRRCI):
            str << "CSRRCI ";
            break;
        default:
            break;
        }
        str << " with src/dest 0x" << std::hex << csr_src_dest;
        str << " and rs1/imm 0x" << std::hex << static_cast<unsigned>(risb_rs1);
        str << " and rd 0x" << std::hex << static_cast<unsigned>(riuj_rd);
        break;
    default:
        break;
    }
}

void cpu_util::make_instruction(Opcode opcode, F3 f3, F7 f7, std::uint8_t rs1,

                                std::uint8_t rs2, std::uint8_t rd,
                                std::uint32_t imm, std::uint32_t data,

                                std::uint32_t rs1_val, std::uint32_t rs2_val,

                                std::uint32_t addr, std::uint32_t cur_iaddr,

                                // mock memory
                                std::map<std::uint32_t, cpu_seq_item> &imem,
                                std::map<std::uint32_t, cpu_seq_item> &dmem,

                                // cur_iaddr + 4 or branch or jump destination
                                std::uint32_t &next_iaddr) {
    /* Make instructions and expected data
     * imem: iaddr ->
     *     input to DUT: idata, rst_n
     * dmem: daddr ->
     *     input to DUT: data
     *     check DUT output: wr, wdata
     * No hazard detection.
     *
     * Only parameters relevant to opcode, (and/or f3, f7) are used, others are
     * ignored.
     * For CSR instructions, rs1 is used for rs1 or uimm[4:0] while imm is used
     * for CSR source/dest
     */

    std::uint32_t imm_12_signed_extended =
        (imm & 0xFFF) | ((((imm & 0xFFF) >> 11) & 1) == 0 ? 0 : 0xFFFFF000);

    std::uint32_t imm_b_12_signed_extended =
        (imm & 0x1FFE) | ((((imm & 0x1FFF) >> 12) & 1) == 0 ? 0 : 0xFFFFE000);

    std::uint32_t baddr = cur_iaddr; // addr after branch, to be set

    std::uint32_t csr_src_dest = imm & 0xFFF;

    cpu_seq_item item, exp_item;

    // default values, to be overwritten
    item.data = 0;
    item.rst_n = true;
    item.iaddr = cur_iaddr;
    next_iaddr = cur_iaddr + 4;

    switch (opcode) {
    case (cpu_util::Opcode::JAL):
        item.idata =
            cpu_util::make_j_type_instruction(cpu_util::Opcode::JAL, rd, imm);

        next_iaddr = imm & 0x001FFFFE |
                     (((imm >> 20) & 0x1) == 0 ? 0 : (0xFFFFFFFF << 20));

        break;
    case (cpu_util::Opcode::JALR):
        item.idata = cpu_util::make_i_type_instruction(cpu_util::Opcode::JALR,
                                                       f3, rd, imm, rs1);
        next_iaddr = imm_12_signed_extended + rs1_val;
        break;
    case (cpu_util::Opcode::RI):
        switch (f3) {
        case (cpu_util::F3::ADDSUB):
        case (cpu_util::F3::SLT):
        case (cpu_util::F3::SLTU):
        case (cpu_util::F3::AND):
        case (cpu_util::F3::OR):
        case (cpu_util::F3::XOR):
            item.idata = cpu_util::make_i_type_instruction(cpu_util::Opcode::RI,
                                                           f3, rd, imm, rs1);
            break;
        case (cpu_util::F3::SLL):
        case (cpu_util::F3::SR):
            item.idata = cpu_util::make_i_type_shift_instruction(
                cpu_util::Opcode::RI, f3, f7, rd, imm, rs1);
            break;
        }

        break;
    case (cpu_util::Opcode::RR):
        item.idata = cpu_util::make_r_type_instruction(cpu_util::Opcode::RR, f3,
                                                       f7, rd, rs1, rs2);

        break;
    case (cpu_util::Opcode::LUI):
    case (cpu_util::Opcode::AUIPC):
        item.idata = cpu_util::make_u_type_instruction(opcode, rd, imm);

        break;

    case (cpu_util::Opcode::L):
        item.idata = cpu_util::make_i_type_instruction(cpu_util::Opcode::L, f3,
                                                       rd, imm, rs1);
        item.data = data;

        exp_item.addr = rs1_val + imm_12_signed_extended;
        exp_item.data = data;
        exp_item.wr = false;
        exp_item.wdata = 0;
        dmem[exp_item.addr] = exp_item;
        break;

    case (cpu_util::Opcode::S):
        item.idata = cpu_util::make_s_type_instruction(cpu_util::Opcode::S, f3,
                                                       rs1, rs2, imm);
        exp_item.addr = rs1_val + imm_12_signed_extended;
        exp_item.wr = true;
        exp_item.data = data;

        switch (f3) {
        case (cpu_util::F3::SW):
            exp_item.wdata = rs2_val;
            break;
        case (cpu_util::F3::SH):
            exp_item.wdata = (rs2_val & 0x0000FFFF) | (data & 0xFFFF0000);
            break;
        case (cpu_util::F3::SB):
            exp_item.wdata = (rs2_val & 0x000000FF) | (data & 0xFFFFFF00);
            break;
        default:
            break;
        }
        dmem[exp_item.addr] = exp_item;
        break;

    case (cpu_util::Opcode::B):
        item.idata = cpu_util::make_b_type_instruction(cpu_util::Opcode::B, f3,
                                                       rs1, rs2, imm);
        baddr = cur_iaddr + 4;
        switch (f3) {
        case (cpu_util::F3::BEQ):
            if (rs1_val == rs2_val)
                baddr = cur_iaddr + imm_b_12_signed_extended;
            break;
        case (cpu_util::F3::BNE):
            if (rs1_val != rs2_val)
                baddr = cur_iaddr + imm_b_12_signed_extended;
            break;
        case (cpu_util::F3::BLT):
            if (static_cast<int>(rs1_val) < static_cast<int>(rs2_val))
                baddr = cur_iaddr + imm_b_12_signed_extended;
            break;
        case (cpu_util::F3::BGE):
            if (static_cast<int>(rs1_val) >= static_cast<int>(rs2_val))
                baddr = cur_iaddr + imm_b_12_signed_extended;
            break;
        case (cpu_util::F3::BLTU):
            if (rs1_val < rs2_val)
                baddr = cur_iaddr + imm_b_12_signed_extended;
            break;
        case (cpu_util::F3::BGEU):
            if (rs1_val >= rs2_val)
                baddr = cur_iaddr + imm_b_12_signed_extended;
            break;
        default:
            break;
        }
        next_iaddr = baddr;
        break;

    case (cpu_util::Opcode::SYS):
        item.idata = cpu_util::make_csr_instruction(cpu_util::Opcode::SYS, f3,
                                                    rd, csr_src_dest, rs1);
        break;
    // not implemented, set to NOP
    case (cpu_util::Opcode::F):
    default:
        item.idata = cpu_util::make_i_type_instruction(
            cpu_util::Opcode::RI, cpu_util::F3::ADDSUB, 0, 0, 0);
        break;
    }

    imem[item.iaddr] = item;
}
