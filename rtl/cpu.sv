`define RLEN 32
`define XLEN 32
`define IALIGN_B 4

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

`define RESET_PC 32'b0

`define CSR_CYCLE 12'hC00
`define CSR_CYCLE_H 12'hC80
`define CSR_INSTRET 12'hC01
`define CSR_INSTRET_H 12'hC81


//`define DEBUG
`ifdef DEBUG
`define PRINT_R_TYPE $strobe("R type: dec_pc=0x%0h rs1=0x%0h rs2=0x%0h rd=0x%0h f7=0x%0h f3=0x%0h",\
dec_pc, r_rs1, r_rs2, r_rd, r_f7, r_f3);
`define PRINT_I_TYPE $strobe(\
"I type: dec_pc=0x%0h rs1=0x%0h imm=0x%0h rd=0x%0h f7=0x%0h f3=0x%0h smt=0x%0h", \
dec_pc, i_rs1, i_imm, i_rd, i_f7, i_f3, i_shamt);
`define PRINT_I_TYPE_2 $strobe(\
"I type: dec_pc=0x%0h rs1=0x%0h imm=0x%0h rd=0x%0h f7=0x%0h f3=0x%0h smt=0x%0h ex_i_rd=0x%0h",\
dec_pc, i_rs1, i_imm, i_rd, i_f7, i_f3, i_shamt, ex_i_rd);
`define PRINT_S_TYPE $strobe(\
"S type: dec_pc=0x%0h rs1=0x%0h rs2=0x%0h f3=0x%0h imm=0x%0h", \
dec_pc, s_rs1, s_rs2, s_f3, s_imm);
`define PRINT_S_TYPE_2 $strobe(\
"S type cycle 2: dec_pc=0x%0h rs1=0x%0h rs2=0x%0h f3=0x%0h imm=0x%0h",\
dec_pc, s_rs1, ex_s_rs2, ex_s_f3, s_imm);
`define PRINT_B_TYPE $strobe("B type: dec_pc=0x%0h rs1=0x%0h rs2=0x%0h f3=0x%0h imm=0x%0h", \
dec_pc, b_rs1, b_rs2, b_f3, b_imm);
`define PRINT_U_TYPE $strobe("U type: dec_pc=0x%0h rd=0x%0h imm=0x%0h", \
dec_pc, u_rd, u_imm);
`define PRINT_J_TYPE $strobe("J type: dec_pc=0x%0h rd=0x%0h imm=0x%0h", \
dec_pc, j_rd, j_imm);
`define PRINT_X \
  $strobe("  x0=0x%0h x1=0x%0h x2=0x%0h x3=0x%0h x4=0x%0h x5=0x%0h x6=0x%0h x7=0x%0h", x[0], x[1], x[2], x[3], x[4], x[5], x[6], x[7]); \
  $strobe("  x8=0x%0h x9=0x%0h x10=0x%0h x11=0x%0h x12=0x%0h x13=0x%0h x14=0x%0h x15=0x%0h", x[8], x[9], x[10], x[11], x[12], x[13], x[14], x[15]); \
  $strobe("  x16=0x%0h x17=0x%0h x18=0x%0h x19=0x%0h x20=0x%0h x21=0x%0h x22=0x%0h x23=0x%0h", x[16], x[17], x[18], x[19], x[20], x[21], x[22], x[23]); \
  $strobe("  x24=0x%0h x25=0x%0h x26=0x%0h x27=0x%0h x28=0x%0h x29=0x%0h x30=0x%0h x31=0x%0h", x[24], x[25], x[26], x[27], x[28], x[29], x[30], x[31]); \
  $strobe("  pc=0x%0h", pc);
`define PRINT_STEP $strobe( \
          "time=%0t opcode=0x%0h pc=0x%0h dec_pc=0x%0h iaddr=0x%0h idata=0x%0h addr=0x%0h data=0x%0h wdata=0x%0h wr=0x%0h pstate=0x%0h do_d=0x%0h", \
          $time, opcode, pc, dec_pc, iaddr, idata, addr, data, wdata, wr, state, do_decode);
`endif



module cpu (
    input logic clk,
    input logic rst_n,

    // Memory
    output logic [31:0] iaddr,
    input  logic [31:0] idata,

    output logic [31:0] addr,
    output logic [31:0] wdata,
    output logic wr,
    input logic [31:0] data

);

  // General-purpose registers
  logic [`XLEN-1:0] x  [`RLEN];

  // Control and Status Registers
  logic [`XLEN-1:0] csr[ 4096];

  logic [`RLEN-1:0] pc;
  assign iaddr = pc;

  // Cycle and Time counter
  logic [63:0] cycle_time;
  assign csr[`CSR_CYCLE]   = cycle_time[31:0];
  assign csr[`CSR_CYCLE_H] = cycle_time[63:32];

  // Instructions retired
  logic [63:0] instret;
  assign csr[`CSR_INSTRET]   = instret[31:0];
  assign csr[`CSR_INSTRET_H] = instret[63:32];


  /* Decode */
  logic [6:0] opcode;

  // R-type
  logic [6:0] r_f7;
  logic [4:0] r_rs2;
  logic [4:0] r_rs1;
  logic signed [31:0] r_rs1_s;
  logic signed [31:0] r_rs2_s;
  logic [2:0] r_f3;
  logic [4:0] r_rd;
  assign r_rs1_s = x[r_rs1];
  assign r_rs2_s = x[r_rs2];

  // I-type
  logic [31:0] i_imm;
  logic signed [31:0] i_imm_s;
  logic [4:0] i_rs1;
  logic signed [31:0] i_rs1_s;
  logic [2:0] i_f3;
  logic [4:0] i_rd;
  logic [4:0] i_shamt;
  logic [6:0] i_f7;
  assign i_shamt = i_imm[4:0];
  assign i_f7 = i_imm[11:5];
  assign i_imm_s = i_imm;
  assign i_rs1_s = x[i_rs1];

  // S-type
  logic [31:0] s_imm;
  logic [4:0] s_rs1;
  logic [4:0] s_rs2;
  logic [2:0] s_f3;

  // B-type (~S)
  logic [31:0] b_imm;
  logic [4:0] b_rs1;
  logic [4:0] b_rs2;
  logic signed [31:0] b_rs1_s;
  logic signed [31:0] b_rs2_s;
  logic [2:0] b_f3;
  assign b_rs1_s = x[b_rs1];
  assign b_rs2_s = x[b_rs2];

  // U-type
  logic [31:0] u_imm;
  logic [ 4:0] u_rd;

  // J-type
  logic [31:0] j_imm;
  logic [ 4:0] j_rd;

  // CSR
  logic [31:0] csr_imm;
  logic [11:0] csr_src_dest;
  logic [ 4:0] csr_rs1;
  logic [ 2:0] csr_f3;
  logic [ 4:0] csr_rd;


  logic [31:0] dec_pc;  // pc of decoded instruction

  always_ff @(posedge clk, negedge rst_n) begin : decode
    if (!rst_n) opcode <= 7'b0;
    else if (do_decode) begin
      // pc is the pc of the next instruction
      // pc - 4 is the pc of the instruction being decoded
      dec_pc <= pc - 4;
      opcode <= idata[6:0];

      {r_f7, r_rs2, r_rs1, r_f3, r_rd} <= {
        idata[31:25], idata[24:20], idata[19:15], idata[14:12], idata[11:7]
      };

      {i_rs1, i_f3, i_rd} <= {idata[19:15], idata[14:12], idata[11:7]};
      i_imm <= {{21{idata[31]}}, idata[30:25], idata[24:21], idata[20]};

      {s_rs2, s_rs1, s_f3} <= {idata[24:20], idata[19:15], idata[14:12]};
      s_imm <= {{21{idata[31]}}, idata[30:25], idata[11:8], idata[7]};

      {b_rs2, b_rs1, b_f3} <= {idata[24:20], idata[19:15], idata[14:12]};
      b_imm <= {{20{idata[31]}}, idata[7], idata[30:25], idata[11:8], 1'b0};

      {u_rd} <= {idata[11:7]};
      u_imm <= {idata[31], idata[30:20], idata[19:12], 12'b0};

      {j_rd} <= {idata[11:7]};
      j_imm <= {{12{idata[31]}}, idata[19:12], idata[20], idata[30:25], idata[24:21], 1'b0};
      {csr_rs1, csr_f3, csr_rd} <= {idata[19:15], idata[14:12], idata[11:7]};
      csr_imm <= {27'b0, idata[19:15]};
    end
  end
  /* End Decode */

  /* Execute */
  logic [6:0] ex_opcode;
  logic [2:0] ex_i_f3;
  logic [4:0] ex_i_rd;
  logic [4:0] ex_s_rs2;
  logic [2:0] ex_s_f3;

  typedef enum {
    EXECUTE,
    WAIT_PC,
    WAIT_DECODE,
    WAIT_L_S,
    WAIT_READ,
    XXX
  } state_e;

  logic   do_decode;
  state_e state;

  always_ff @(posedge clk, negedge rst_n) begin : execute
    if (!rst_n) begin
      state <= WAIT_PC;
      pc <= `RESET_PC;
      do_decode <= '0;
      wr <= '0;
      cycle_time <= '0;
      instret <= '0;
    end else begin

      pc <= pc + 4;
      do_decode <= '1;
      wr <= 0;
      cycle_time <= cycle_time + 1;

      case (state)
        EXECUTE: begin
          instret <= instret + 1;
          case (opcode)
            `OP_LUI: begin
              x[u_rd] <= u_imm;
            end
            `OP_AUIPC: begin
              x[u_rd] <= dec_pc + u_imm;
            end
            `OP_JAL: begin
              x[j_rd] <= dec_pc + 4;
              if (j_imm != dec_pc + 4) begin
                pc <= j_imm;
                do_decode <= '0;
                state <= WAIT_PC;
              end
              // else pc = pc + 4 is valid
              // should check addr alignment
            end
            `OP_JALR: begin
              x[i_rd] <= dec_pc + 4;
              // should check addr alignment
              if (((i_imm + x[i_rs1]) & 32'hFFFFFFFE) != dec_pc + 4) begin
                pc <= (i_imm + x[i_rs1]) & 32'hFFFFFFFE;
                do_decode <= '0;
                state <= WAIT_PC;
              end
            end
            `OP_B: begin
              case (b_f3)
                `F3_BEQ: begin
                  if (x[b_rs1] == x[b_rs2]) begin
                    pc <= dec_pc + b_imm;
                    do_decode <= '0;
                    state <= WAIT_PC;
                  end
                end
                `F3_BNE: begin
                  if (x[b_rs1] != x[b_rs2]) begin
                    pc <= dec_pc + b_imm;
                    do_decode <= '0;
                    state <= WAIT_PC;
                  end
                end
                `F3_BLT: begin
                  if (b_rs1_s < b_rs2_s) begin
                    pc <= dec_pc + b_imm;
                    do_decode <= '0;
                    state <= WAIT_PC;
                  end
                end
                `F3_BGE: begin
                  if (b_rs1_s >= b_rs2_s) begin
                    pc <= dec_pc + b_imm;
                    do_decode <= '0;
                    state <= WAIT_PC;
                  end
                end
                `F3_BLTU: begin
                  if (x[b_rs1] < x[b_rs2]) begin
                    pc <= dec_pc + b_imm;
                    do_decode <= '0;
                    state <= WAIT_PC;
                  end
                end
                `F3_BGEU: begin
                  if (x[b_rs1] >= x[b_rs2]) begin
                    pc <= dec_pc + b_imm;
                    do_decode <= '0;
                    state <= WAIT_PC;
                  end
                end
                default: begin
                end
              endcase
            end
            `OP_L: begin
              addr <= x[i_rs1] + i_imm;
              ex_opcode <= opcode;
              ex_i_f3 <= i_f3;
              ex_i_rd <= i_rd;

              instret <= instret;
              pc <= pc;
              do_decode <= '0;
              state <= WAIT_READ;
            end
            `OP_S: begin
              addr <= x[s_rs1] + s_imm;
              ex_opcode <= opcode;
              ex_s_f3 <= s_f3;
              ex_s_rs2 <= s_rs2;

              instret <= instret;
              pc <= pc;
              do_decode <= '0;
              state <= WAIT_READ;
            end
            `OP_RI: begin
              case (i_f3)
                `F3_ADDSUB: begin
                  x[i_rd] <= x[i_rs1] + i_imm;
                end
                `F3_SLT: begin
                  x[i_rd] <= i_rs1_s < i_imm_s ? 32'h0000_0001 : '0;
                end
                `F3_SLTU: begin
                  x[i_rd] <= x[i_rs1] < i_imm ? 32'h0000_0001 : '0;
                end
                `F3_XOR: begin
                  x[i_rd] <= x[i_rs1] ^ i_imm;
                end
                `F3_OR: begin
                  x[i_rd] <= x[i_rs1] | i_imm;
                end
                `F3_AND: begin
                  x[i_rd] <= x[i_rs1] & i_imm;
                end
                `F3_SLL: begin
                  x[i_rd] <= x[i_rs1] << i_shamt;
                end
                `F3_SR: begin
                  if (i_f7 == `F7_SRL) x[i_rd] <= x[i_rs1] >> i_shamt;
                  else x[i_rd] <= i_rs1_s >>> i_shamt;
                end
                default: begin
                end
              endcase
            end
            `OP_RR: begin
              case (r_f3)
                `F3_ADDSUB: begin
                  if (r_f7 == `F7_ADD) x[r_rd] <= x[r_rs1] + x[r_rs2];
                  else x[r_rd] <= x[r_rs1] - x[r_rs2];
                end
                `F3_SLT: begin
                  x[r_rd] <= r_rs1_s < r_rs2_s ? 32'h0000_0001 : '0;
                end
                `F3_SLTU: begin
                  x[r_rd] <= x[r_rs1] < x[r_rs2] ? 32'h0000_0001 : '0;
                end
                `F3_XOR: begin
                  x[r_rd] <= x[r_rs1] ^ x[r_rs2];
                end
                `F3_OR: begin
                  x[r_rd] <= x[r_rs1] | x[r_rs2];
                end
                `F3_AND: begin
                  x[r_rd] <= x[r_rs1] & x[r_rs2];
                end
                `F3_SLL: begin
                  x[r_rd] <= x[r_rs1] << x[r_rs2];
                end
                `F3_SR: begin
                  if (r_f7 == `F7_SRL) x[r_rd] <= x[r_rs1] >> x[r_rs2];
                  else x[r_rd] <= r_rs1_s >>> x[r_rs2];
                end
                default: begin
                end
              endcase
            end
            `OP_F: begin
            end
            `OP_SYS: begin
              case (csr_f3)
                `F3_CSRRW: begin
                  csr[csr_src_dest] <= x[csr_rs1];
                  if (csr_rd != 0) x[csr_rd] <= csr[csr_src_dest];
                end
                `F3_CSRRS: begin
                  x[csr_rd] <= csr[csr_src_dest];
                  if (csr_rs1 != 0) csr[csr_src_dest] <= csr[csr_src_dest] | x[csr_rs1];
                end
                `F3_CSRRC: begin
                  x[csr_rd] <= csr[csr_src_dest];
                  if (csr_rs1 != 0) csr[csr_src_dest] <= csr[csr_src_dest] & (~x[csr_rs1]);
                end
                `F3_CSRRWI: begin
                  csr[csr_src_dest] <= csr_imm;
                  if (csr_rd != 0) x[csr_rd] <= csr[csr_src_dest];
                end
                `F3_CSRRSI: begin
                  x[csr_rd] <= csr[csr_src_dest];
                  if (csr_imm != 0) csr[csr_src_dest] <= csr[csr_src_dest] | csr_imm;
                end
                `F3_CSRRCI: begin
                  x[csr_rd] <= csr[csr_src_dest];
                  if (csr_imm != 0) csr[csr_src_dest] <= csr[csr_src_dest] & (~csr_imm);
                end
                default: begin
                end
              endcase
            end
            default: begin
              pc <= pc;
            end
          endcase  // opcode
        end
        WAIT_PC: begin
          //pc <= pc;
          do_decode <= '1;
          state <= WAIT_DECODE;
        end
        WAIT_DECODE: begin
          do_decode <= '1;
          state <= EXECUTE;
        end
        WAIT_READ: begin
          pc <= pc;
          do_decode <= '0;
          state <= WAIT_L_S;
        end
        WAIT_L_S: begin
          instret <= instret + 1;
          do_decode <= '1;
          state <= EXECUTE;
          if (ex_opcode == `OP_L)
            case (ex_i_f3)
              `F3_LB: begin
                x[ex_i_rd] <= {{24{data[7]}}, data[7:0]};
              end
              `F3_LH: begin
                x[ex_i_rd] <= {{16{data[15]}}, data[15:0]};
              end
              `F3_LW: begin
                x[ex_i_rd] <= data;
              end
              `F3_LBU: begin
                x[ex_i_rd] <= {{24'b0}, data[7:0]};
              end
              `F3_LHU: begin
                x[ex_i_rd] <= {{16'b0}, data[15:0]};
              end
              default: begin
              end
            endcase  // OP_L f3
          else if (ex_opcode == `OP_S) begin
            wr <= '1;
            case (ex_s_f3)
              `F3_SB: begin
                wdata <= {data[31:8], x[ex_s_rs2][7:0]};
              end
              `F3_SH: begin
                wdata <= {data[31:16], x[ex_s_rs2][15:0]};
              end
              `F3_SW: begin
                wdata <= x[ex_s_rs2];
              end
              default: begin
              end
            endcase  // OP_S f3
          end
        end
        default: begin
        end
      endcase  // state
    end
    x[0] <= '0;  // hardwire to 0
  end


`ifdef DEBUG
  always_ff @(posedge clk, negedge rst_n) begin : debug
    if (!rst_n) begin
    end else begin
      `PRINT_STEP
      case (state)
        EXECUTE: begin
          case (opcode)
            `OP_LUI: begin
              `PRINT_U_TYPE
            end
            `OP_AUIPC: begin
              `PRINT_U_TYPE
            end
            `OP_JAL: begin
              `PRINT_J_TYPE
            end
            `OP_JALR: begin
              `PRINT_I_TYPE
            end
            `OP_B: begin
              `PRINT_B_TYPE
            end
            `OP_L: begin
              `PRINT_I_TYPE
            end
            `OP_S: begin
              `PRINT_S_TYPE
            end
            `OP_RI: begin
              `PRINT_I_TYPE
            end
            `OP_RR: begin
              `PRINT_R_TYPE
            end
            `OP_F: begin
            end
            `OP_SYS: begin
            end
            default: begin
            end
          endcase  // opcode
        end
        WAIT_PC: begin
        end
        WAIT_DECODE: begin
        end
        WAIT_READ: begin
        end
        WAIT_L_S: begin
          if (ex_opcode == `OP_L) `PRINT_I_TYPE_2
          else if (ex_opcode == `OP_S) `PRINT_S_TYPE_2
        end
        default: begin
        end
      endcase
    end
    `PRINT_X
  end
`endif

endmodule
