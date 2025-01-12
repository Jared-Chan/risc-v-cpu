`define OP_LUI 7'b0110111
`define OP_AUIPC 7'b0010111
`define OP_JAL 7'b1101111
`define OP_JALR 7'b1100111
`define OP_B 7'b1100011 // branch
`define OP_L 7'b0000011 // load
`define OP_S 7'b0100011 // store
`define OP_RI 7'b0010011 // reg-imm
`define OP_RR 7'b0110011 // reg-reg
`define OP_F 7'b0001111 // fence
`define OP_SYS 7'b1110011 // system

`define F3_BEQ 3'b000
`define F3_BNE 3'b001
`define F3_BLT 3'b100
`define F3_BGE 3'b101
`define F3_BLTU 3'b110
`define F3_BGEU 3'b111

`define F3_LB 3'b000
`define F3_LH 3'b001
`define F3_LW 3'b010
`define F3_LBU 3'b100
`define F3_LHU 3'b101

`define F3_SB 3'b000
`define F3_SH 3'b001
`define F3_SW 3'b010

`define F3_ADDSUB 3'b000
`define F3_SLT 3'b010
`define F3_SLTU 3'b011
`define F3_XOR 3'b100
`define F3_OR 3'b110
`define F3_AND 3'b111
`define F3_SLL 3'b001
`define F3_SR 3'b101

`define F3_CSRRW 3'b001
`define F3_CSRRS 3'b010
`define F3_CSRRC 3'b011
`define F3_CSRRWI 3'b101
`define F3_CSRRSI 3'b110
`define F3_CSRRCI 3'b111

`define F7_ADD 7'b0
`define F7_SUB 7'b0100000
`define F7_SRL 7'b0
`define F7_SRA 7'b0100000


//`define DEBUG
`ifdef DEBUG
`define PRINT_R_TYPE $strobe("R type: dec_pc=0x%0h rs1=0x%0h rs2=0x%0h rd=0x%0h f7=0x%0h f3=0x%0h",\
dec_pc, rs1, rs2, rd, f7, f3);
`define PRINT_I_TYPE $strobe(\
"I type: dec_pc=0x%0h rs1=0x%0h imm=0x%0h rd=0x%0h f7=0x%0h f3=0x%0h smt=0x%0h", \
dec_pc, rs1, i_imm, rd, i_f7, f3, i_shamt);
`define PRINT_I_TYPE_2 $strobe(\
"I type: dec_pc=0x%0h rs1=0x%0h imm=0x%0h rd=0x%0h f7=0x%0h f3=0x%0h smt=0x%0h ex_i_rd=0x%0h",\
dec_pc, rs1, i_imm, rd, i_f7, f3, i_shamt, ex_rd);
`define PRINT_S_TYPE $strobe(\
"S type: dec_pc=0x%0h rs1=0x%0h rs2=0x%0h f3=0x%0h imm=0x%0h", \
dec_pc, rs1, rs2, f3, s_imm);
`define PRINT_S_TYPE_2 $strobe(\
"S type cycle 2: dec_pc=0x%0h rs1=0x%0h rs2=0x%0h f3=0x%0h imm=0x%0h",\
dec_pc, rs1, ex_s_rs2, ex_f3, s_imm);
`define PRINT_B_TYPE $strobe("B type: dec_pc=0x%0h rs1=0x%0h rs2=0x%0h f3=0x%0h imm=0x%0h", \
dec_pc, rs1, rs2, f3, b_imm);
`define PRINT_U_TYPE $strobe("U type: dec_pc=0x%0h rd=0x%0h imm=0x%0h", \
dec_pc, rd, u_imm);
`define PRINT_J_TYPE $strobe("J type: dec_pc=0x%0h rd=0x%0h imm=0x%0h", \
dec_pc, rd, j_imm);
`define PRINT_X \
  $strobe("  x0=0x%0h x1=0x%0h x2=0x%0h x3=0x%0h x4=0x%0h x5=0x%0h x6=0x%0h x7=0x%0h", x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7]); \
  $strobe("  x8=0x%0h x9=0x%0h x10=0x%0h x11=0x%0h x12=0x%0h x13=0x%0h x14=0x%0h x15=0x%0h", x[8], x[9], x[10], x[11], x[12], x[13], x[14], x[15]); \
  $strobe("  x16=0x%0h x17=0x%0h x18=0x%0h x19=0x%0h x20=0x%0h x21=0x%0h x22=0x%0h x23=0x%0h", x[16], x[17], x[18], x[19], x[20], x[21], x[22], x[23]); \
  $strobe("  x24=0x%0h x25=0x%0h x26=0x%0h x27=0x%0h x28=0x%0h x29=0x%0h x30=0x%0h x31=0x%0h", x[24], x[25], x[26], x[27], x[28], x[29], x[30], x[31]); \
  $strobe("  pc=0x%0h", pc);
`define PRINT_STEP $strobe( \
          "time=%0t opcode=0x%2h pc=0x%8h dec_pc=0x%8h iaddr_o=0x%8h idata_i=0x%8h addr_o=0x%8h data_i=0x%8h wdata_o=0x%8h wr_o=0x%1h pstate=0x%1h do_d=0x%1h", \
          $time, opcode, pc, dec_pc, iaddr_o, idata_i, addr_o, data_i, wdata_o, wr_o, state, do_decode);
`define PRINT_JAL $display("JAL: dec_pc=0x%0h rd=0x%0h imm=0x%0h", \
dec_pc, rd, j_imm);
`define PRINT_JALR $display(\
"JALR: dec_pc=0x%0h rs1=0x%0h imm=0x%0h rd=0x%0h f7=0x%0h f3=0x%0h smt=0x%0h", \
dec_pc, rs1, i_imm, rd, i_f7, f3, i_shamt);
`else
`define PRINT_R_TYPE
`define PRINT_I_TYPE
`define PRINT_I_TYPE_2
`define PRINT_S_TYPE
`define PRINT_S_TYPE_2
`define PRINT_B_TYPE
`define PRINT_U_TYPE
`define PRINT_J_TYPE
`define PRINT_X
`define PRINT_STEP
`define PRINT_JAL
`define PRINT_JALR
`endif

