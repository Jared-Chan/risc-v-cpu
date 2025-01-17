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

`define CSR_CYCLE 12'hC00
`define CSR_CYCLE_H 12'hC80
`define CSR_TIME 12'hC01
`define CSR_TIME_H 12'hC81
`define CSR_INSTRET 12'hC02
`define CSR_INSTRET_H 12'hC82


`ifdef DEBUG
`define PRINT_R_TYPE $display(\
"R type: dec_pc=0x%0h rs1=0x%0h rs2=0x%0h rd=0x%0h f7=0x%0h f3=0x%0h",\
dec_pc, rs1, rs2, rd, f7, f3);
`define PRINT_I_TYPE $display(\
"I type: dec_pc=0x%0h rs1=0x%0h imm=0x%0h rd=0x%0h f7=0x%0h f3=0x%0h smt=0x%0h", \
dec_pc, rs1, i_imm, rd, i_f7, f3, i_shamt);
`define PRINT_I_TYPE_2 $display(\
"I type: dec_pc=0x%0h rs1=0x%0h imm=0x%0h rd=0x%0h f7=0x%0h f3=0x%0h smt=0x%0h ex_i_rd=0x%0h",\
dec_pc, rs1, i_imm, rd, i_f7, f3, i_shamt, ex_rd);
`define PRINT_S_TYPE $display(\
"S type: dec_pc=0x%0h rs1=0x%0h rs2=0x%0h f3=0x%0h imm=0x%0h", \
dec_pc, rs1, rs2, f3, s_imm);
`define PRINT_S_TYPE_2 $display(\
"S type cycle 2: dec_pc=0x%0h rs1=0x%0h rs2=0x%0h f3=0x%0h imm=0x%0h",\
dec_pc, rs1, ex_s_rs2, ex_f3, s_imm);
`define PRINT_B_TYPE $display("B type: dec_pc=0x%0h rs1=0x%0h rs2=0x%0h f3=0x%0h imm=0x%0h", \
dec_pc, rs1, rs2, f3, b_imm);
`define PRINT_U_TYPE $display("U type: dec_pc=0x%0h rd=0x%0h imm=0x%0h", \
dec_pc, rd, u_imm);
`define PRINT_J_TYPE $display("J type: dec_pc=0x%0h rd=0x%0h imm=0x%0h", \
dec_pc, rd, j_imm);
`define PRINT_X \
  $strobe("  x0=0x%0h x1=0x%0h x2=0x%0h x3=0x%0h x4=0x%0h x5=0x%0h x6=0x%0h x7=0x%0h", x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7]); \
  $strobe("  x8=0x%0h x9=0x%0h xa=0x%0h xb=0x%0h xc=0x%0h xd=0x%0h xe=0x%0h xf=0x%0h", x[8], x[9], x[10], x[11], x[12], x[13], x[14], x[15]); \
  $strobe("  x10=0x%0h x11=0x%0h x12=0x%0h x13=0x%0h x14=0x%0h x15=0x%0h x16=0x%0h x17=0x%0h", x[16], x[17], x[18], x[19], x[20], x[21], x[22], x[23]); \
  $strobe("  x18=0x%0h x19=0x%0h x1a=0x%0h x1b=0x%0h x1c=0x%0h x1d=0x%0h x1e=0x%0h x1f=0x%0h", x[24], x[25], x[26], x[27], x[28], x[29], x[30], x[31]); \
  $strobe("  pc=0x%0h", pc);
`define PRINT_STEP $display( \
          "time=%0t before opcode=0x%2h pc=0x%8h dec_pc=0x%8h iaddr_o=0x%8h idata_i=0x%8h addr_o=0x%8h data_i=0x%8h wdata_o=0x%8h wr_o=0x%1h pstate=0x%1h do_d=0x%1h", \
          $time, opcode, pc, dec_pc, iaddr_o, idata_i, addr_o, data_i, wdata_o, wr_o, state, do_decode); \
$strobe( \
          "time=%0t after  opcode=0x%2h pc=0x%8h dec_pc=0x%8h iaddr_o=0x%8h idata_i=0x%8h addr_o=0x%8h data_i=0x%8h wdata_o=0x%8h wr_o=0x%1h pstate=0x%1h do_d=0x%1h", \
          $time, opcode, pc, dec_pc, iaddr_o, idata_i, addr_o, data_i, wdata_o, wr_o, state, do_decode);
`define PRINT_JAL $display("JAL: dec_pc=0x%0h rd=0x%0h imm=0x%0h", \
dec_pc, rd, j_imm);
`define PRINT_JALR $display(\
"JALR: dec_pc=0x%0h rs1=0x%0h imm=0x%0h rd=0x%0h f7=0x%0h f3=0x%0h smt=0x%0h", \
dec_pc, rs1, i_imm, rd, i_f7, f3, i_shamt);
`define TRACE $display(\
"time=%0t \x1B[32mTRACE BEFORE\033[0m opcode=0x%8h dec_pc=0x%8h branch_dest=0x%8h auipc_result=0x%8h x_rs1=0x%8h x_rs2=0x%8h rs1_reg=0x%8h rd_reg=0x%8h f7_reg=0x%8h f3_reg=0x%8h u_imm_reg=0x%8h j_rd=0x%8h j_dest=0x%8h load_addr=0x%8h s_addr_reg=0x%8h alu_operand_1=0x%8h alu_operand_2=0x%8h comp_operand_1=0x%8h comp_operand_2=0x%8h csr_src_dest=0x%8h csr_idx=0x%8h csr_read_only=0x%8h state=0x%8h pc=0x%8h do_decode=0x%8h wr_o=0x%8h data_addr_strobe_o=0x%8h cycle=0x%8h time_cnt=0x%8h clk_cnt=0x%8h instret=0x%8h byte_en_o=0x%8h x[rd_reg]=0x%8h full_addr_o=0x%8h ex_opcode=0x%8h ex_f3=0x%8h ex_rd=0x%8h wdata_o=0x%8h csr[csr_idx]=0x%8h x[ex_rd]=0x%8h x[0]=0x%8h csr[CYCLE]=0x%8h csr[CYCLE_H]=0x%8h csr[TIME]=0x%8h csr[TIME_H]=0x%8h csr[INSTRET]=0x%8h csr[INSTRET_H]=0x%8h", $time, opcode, dec_pc, branch_dest, auipc_result, x_rs1, x_rs2, rs1_reg, rd_reg, f7_reg, f3_reg, u_imm_reg, j_rd, j_dest, load_addr, s_addr_reg, alu_operand_1, alu_operand_2, comp_operand_1, comp_operand_2, csr_src_dest, csr_idx, csr_read_only, state, pc, do_decode, wr_o, data_addr_strobe_o, cycle, time_cnt, clk_cnt, instret, byte_en_o, x[rd_reg], full_addr_o, ex_opcode, ex_f3, ex_rd, wdata_o, csr[csr_idx], x[ex_rd], x[0], csr[CYCLE], csr[CYCLE_H], csr[TIME], csr[TIME_H], csr[INSTRET], csr[INSTRET_H]);\
$strobe(\
"time=%0t \x1B[32mTRACE AFTER\033[0m opcode=0x%8h dec_pc=0x%8h branch_dest=0x%8h auipc_result=0x%8h x_rs1=0x%8h x_rs2=0x%8h rs1_reg=0x%8h rd_reg=0x%8h f7_reg=0x%8h f3_reg=0x%8h u_imm_reg=0x%8h j_rd=0x%8h j_dest=0x%8h load_addr=0x%8h s_addr_reg=0x%8h alu_operand_1=0x%8h alu_operand_2=0x%8h comp_operand_1=0x%8h comp_operand_2=0x%8h csr_src_dest=0x%8h csr_idx=0x%8h csr_read_only=0x%8h state=0x%8h pc=0x%8h do_decode=0x%8h wr_o=0x%8h data_addr_strobe_o=0x%8h cycle=0x%8h time_cnt=0x%8h clk_cnt=0x%8h instret=0x%8h byte_en_o=0x%8h x[rd_reg]=0x%8h full_addr_o=0x%8h ex_opcode=0x%8h ex_f3=0x%8h ex_rd=0x%8h wdata_o=0x%8h csr[csr_idx]=0x%8h x[ex_rd]=0x%8h x[0]=0x%8h csr[CYCLE]=0x%8h csr[CYCLE_H]=0x%8h csr[TIME]=0x%8h csr[TIME_H]=0x%8h csr[INSTRET]=0x%8h csr[INSTRET_H]=0x%8h", $time, opcode, dec_pc, branch_dest, auipc_result, x_rs1, x_rs2, rs1_reg, rd_reg, f7_reg, f3_reg, u_imm_reg, j_rd, j_dest, load_addr, s_addr_reg, alu_operand_1, alu_operand_2, comp_operand_1, comp_operand_2, csr_src_dest, csr_idx, csr_read_only, state, pc, do_decode, wr_o, data_addr_strobe_o, cycle, time_cnt, clk_cnt, instret, byte_en_o, x[rd_reg], full_addr_o, ex_opcode, ex_f3, ex_rd, wdata_o, csr[csr_idx], x[ex_rd], x[0], csr[CYCLE], csr[CYCLE_H], csr[TIME], csr[TIME_H], csr[INSTRET], csr[INSTRET_H]);
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
`define TRACE
`endif

