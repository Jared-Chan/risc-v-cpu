`include "config.svh"
`include "cpu.svh"

module cpu (
    input logic clk,
    input logic rst_n,

    // Memory
    output logic [29:0] iaddr_o,
    input logic [31:0] idata_i,
    output logic [29:0] addr_o,
    output logic [31:0] wdata_o,
    input logic [31:0] data_i,
    output logic wr_o,
    output logic data_addr_strobe_o,
    output logic [3:0] ibyte_en_o,
    output logic [3:0] byte_en_o

);

  // General-purpose registers
  logic [`XLEN-1:0] x  [`RLEN];

  logic [`RLEN-1:0] pc;
  assign iaddr_o = pc[31:2];
  assign ibyte_en_o = 4'b1111;

  logic [31:0] full_addr_o;
  assign addr_o = full_addr_o[31:2];

  typedef enum {
      CYCLE,
      CYCLE_H,
      TIME,
      TIME_H,
      INSTRET,
      INSTRET_H,
      XSUPPORT // unsupported CSR
  } csr_e;

  // Control and Status Registers
  logic [`XLEN-1:0] csr[ 6];

  // Cycle and Time counter
  logic [63:0] cycle_time;
  // Instructions retired
  logic [63:0] instret;

  /* Decode */
  logic [6:0] opcode;

  logic [6:0] f7;
  logic [4:0] rs2;
  logic signed [31:0] rs2_s;
  assign rs2_s = x[rs2];
  logic [4:0] rs1;
  logic signed [31:0] rs1_s;
  assign rs1_s = x[rs1];
  logic [2:0] f3;
  logic [4:0] rd;

  // I-type
  logic [31:0] i_imm;
  logic signed [31:0] i_imm_s;
  logic [4:0] i_shamt;
  logic [6:0] i_f7;
  assign i_shamt = i_imm[4:0];
  assign i_f7 = i_imm[11:5];
  assign i_imm_s = i_imm;

  // S-type
  logic [31:0] s_imm;

  // B-type (~S)
  logic [31:0] b_imm;

  // U-type
  logic [31:0] u_imm;

  // J-type
  logic [31:0] j_imm;

  // CSR
  logic [31:0] csr_imm;
  assign csr_imm = {27'b0, rs1};
  logic [11:0] csr_src_dest;
  csr_e csr_idx;
  logic csr_read_only;


  logic [31:0] dec_pc;  // pc of decoded instruction

  always_ff @(posedge clk, negedge rst_n) begin : decode
    if (!rst_n) opcode <= 7'b0;
    else if (do_decode) begin
      // pc is the pc of the next instruction
      // pc - 4 is the pc of the instruction being decoded
      dec_pc <= pc - 4;
      opcode <= idata_i[6:0];

      {f7, rs2, rs1, f3, rd} <= {
        idata_i[31:25], idata_i[24:20], idata_i[19:15], idata_i[14:12], idata_i[11:7]
      };

      i_imm <= {{21{idata_i[31]}}, idata_i[30:25], idata_i[24:21], idata_i[20]};

      s_imm <= {{21{idata_i[31]}}, idata_i[30:25], idata_i[11:8], idata_i[7]};

      b_imm <= {{20{idata_i[31]}}, idata_i[7], idata_i[30:25], idata_i[11:8], 1'b0};

      u_imm <= {idata_i[31], idata_i[30:20], idata_i[19:12], 12'b0};

      j_imm <= {
        {12{idata_i[31]}}, idata_i[19:12], idata_i[20], idata_i[30:25], idata_i[24:21], 1'b0
      };

      csr_src_dest <= idata_i[31:20];
      case (idata_i[31:20])
          `CSR_CYCLE: csr_idx <= CYCLE;
          `CSR_CYCLE_H: csr_idx <= CYCLE_H;
          `CSR_TIME: csr_idx <= TIME;
          `CSR_TIME_H: csr_idx <= TIME_H;
          `CSR_INSTRET: csr_idx <= INSTRET;
          `CSR_INSTRET_H: csr_idx <= INSTRET_H;
          default: csr_idx <= XSUPPORT;
      endcase
      csr_read_only <= idata_i[31:30] == 2'b11 ? 1'b1 : 1'b0;
    end
  end
  /* End Decode */

  /* Execute */
  logic [6:0] ex_opcode;
  logic [2:0] ex_f3;
  logic [4:0] ex_rd;
  logic [4:0] ex_s_rs2;

  typedef enum {
    EXECUTE,
    WAIT_PC,
    WAIT_DECODE,
    WAIT_L,
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
      wr_o <= '0;
      data_addr_strobe_o <= '0;
      cycle_time <= '0;
      instret <= '0;
      byte_en_o <= 4'b1111;
    end else begin

      pc <= pc + 32'h4;
      do_decode <= '1;
      wr_o <= 0;
      data_addr_strobe_o <= '0;
      cycle_time <= cycle_time + 1'b1;
      byte_en_o <= 4'b1111;

      unique case (state)
        EXECUTE: begin
          instret <= instret + 1'b1;
          unique case (opcode)
            `OP_LUI: begin
              x[rd] <= u_imm;
            end
            `OP_AUIPC: begin
              x[rd] <= dec_pc + u_imm;
            end
            `OP_JAL: begin
              x[rd] <= dec_pc + 4;
              if (j_imm != 4) begin
                pc <= dec_pc + j_imm;
                do_decode <= '0;
                state <= WAIT_PC;
              end
              // else pc = pc + 4 is valid
              // should check addr alignment
            end
            `OP_JALR: begin
              x[rd] <= dec_pc + 4;
              // should check addr alignment
              if (((i_imm + x[rs1]) & 32'hFFFFFFFE) != dec_pc + 4) begin
                pc <= (i_imm + x[rs1]) & 32'hFFFFFFFE;
                do_decode <= '0;
                state <= WAIT_PC;
              end
            end
            `OP_B: begin
              unique case (f3)
                `F3_BEQ: begin
                  if (x[rs1] == x[rs2]) begin
                    pc <= dec_pc + b_imm;
                    do_decode <= '0;
                    state <= WAIT_PC;
                  end
                end
                `F3_BNE: begin
                  if (x[rs1] != x[rs2]) begin
                    pc <= dec_pc + b_imm;
                    do_decode <= '0;
                    state <= WAIT_PC;
                  end
                end
                `F3_BLT: begin
                  if (rs1_s < rs2_s) begin
                    pc <= dec_pc + b_imm;
                    do_decode <= '0;
                    state <= WAIT_PC;
                  end
                end
                `F3_BGE: begin
                  if (rs1_s >= rs2_s) begin
                    pc <= dec_pc + b_imm;
                    do_decode <= '0;
                    state <= WAIT_PC;
                  end
                end
                `F3_BLTU: begin
                  if (x[rs1] < x[rs2]) begin
                    pc <= dec_pc + b_imm;
                    do_decode <= '0;
                    state <= WAIT_PC;
                  end
                end
                `F3_BGEU: begin
                  if (x[rs1] >= x[rs2]) begin
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
              data_addr_strobe_o <= '1;
              full_addr_o <= x[rs1] + i_imm;
              ex_opcode <= opcode;
              ex_f3 <= f3;
              ex_rd <= rd;

              instret <= instret;
              pc <= pc;
              do_decode <= '0;
              state <= WAIT_READ;
            end
            `OP_S: begin
              data_addr_strobe_o <= '1;
              full_addr_o <= x[rs1] + s_imm;
              wr_o <= '1;

              unique case (f3)
                `F3_SB: begin
                  unique case ({(x[rs1] + s_imm)}[1:0])
                    2'b00: begin
                      wdata_o   <= {24'b0, x[rs2][7:0]};
                      byte_en_o <= 4'b0001;
                    end
                    2'b01: begin
                      wdata_o   <= {16'b0, x[rs2][7:0], 8'b0};
                      byte_en_o <= 4'b0010;
                    end
                    2'b10: begin
                      wdata_o   <= {8'b0, x[rs2][7:0], 16'b0};
                      byte_en_o <= 4'b0100;
                    end
                    2'b11: begin
                      wdata_o   <= {x[rs2][7:0], 24'b0};
                      byte_en_o <= 4'b1000;
                    end
                    default: ;
                  endcase
                end
                `F3_SH: begin
                  unique case ({(x[rs1] + s_imm)}[1:0])
                    2'b00: begin
                      wdata_o   <= {16'b0, x[rs2][15:0]};
                      byte_en_o <= 4'b0011;
                    end
                    2'b01: begin
                      wdata_o   <= {8'b0, x[rs2][15:0], 8'b0};
                      byte_en_o <= 4'b0110;
                    end
                    2'b10: begin
                      wdata_o   <= {x[rs2][15:0], 16'b0};
                      byte_en_o <= 4'b1100;
                    end
                    2'b11: begin
                      assert (0 && |"Illegal SH");
                      wdata_o   <= '0;
                      byte_en_o <= 4'b0000;
                    end
                    default: ;
                  endcase
                end
                `F3_SW: begin
                  wdata_o <= x[rs2];
                end
                default: begin
                end
              endcase  // OP_S f3
            end
            `OP_RI: begin
              unique case (f3)
                `F3_ADDSUB: begin
                  x[rd] <= x[rs1] + i_imm;
                end
                `F3_SLT: begin
                  x[rd] <= rs1_s < i_imm_s ? 32'h0000_0001 : '0;
                end
                `F3_SLTU: begin
                  x[rd] <= x[rs1] < i_imm ? 32'h0000_0001 : '0;
                end
                `F3_XOR: begin
                  x[rd] <= x[rs1] ^ i_imm;
                end
                `F3_OR: begin
                  x[rd] <= x[rs1] | i_imm;
                end
                `F3_AND: begin
                  x[rd] <= x[rs1] & i_imm;
                end
                `F3_SLL: begin
                  x[rd] <= x[rs1] << i_shamt;
                end
                `F3_SR: begin
                  if (i_f7 == `F7_SRL) x[rd] <= x[rs1] >> i_shamt;
                  else x[rd] <= rs1_s >>> i_shamt;
                end
                default: begin
                end
              endcase
            end
            `OP_RR: begin
              unique case (f3)
                `F3_ADDSUB: begin
                  if (f7 == `F7_ADD) x[rd] <= x[rs1] + x[rs2];
                  else x[rd] <= x[rs1] - x[rs2];
                end
                `F3_SLT: begin
                  x[rd] <= rs1_s < rs2_s ? 32'h0000_0001 : '0;
                end
                `F3_SLTU: begin
                  x[rd] <= x[rs1] < x[rs2] ? 32'h0000_0001 : '0;
                end
                `F3_XOR: begin
                  x[rd] <= x[rs1] ^ x[rs2];
                end
                `F3_OR: begin
                  x[rd] <= x[rs1] | x[rs2];
                end
                `F3_AND: begin
                  x[rd] <= x[rs1] & x[rs2];
                end
                `F3_SLL: begin
                  x[rd] <= x[rs1] << x[rs2];
                end
                `F3_SR: begin
                  if (f7 == `F7_SRL) x[rd] <= x[rs1] >> x[rs2];
                  else x[rd] <= rs1_s >>> x[rs2];
                end
                default: begin
                end
              endcase
            end
            `OP_F: begin
            end
            `OP_SYS: begin
                if (csr_idx == XSUPPORT) assert(0 && |"Accessing unsupported CSR");
              unique case (f3)
                `F3_CSRRW: begin
                  if (!csr_read_only) csr[csr_idx] <= x[rs1];
                  if (rd != 0) x[rd] <= csr[csr_idx];
                end
                `F3_CSRRS: begin
                  x[rd] <= csr[csr_idx];
                  if (rs1 != 0 && !csr_read_only) csr[csr_idx] <= csr[csr_idx] | x[rs1];
                end
                `F3_CSRRC: begin
                  x[rd] <= csr[csr_idx];
                  if (rs1 != 0 && !csr_read_only) csr[csr_idx] <= csr[csr_idx] & (~x[rs1]);
                end
                `F3_CSRRWI: begin
                  if (!csr_read_only) csr[csr_idx] <= csr_imm;
                  if (rd != 0) x[rd] <= csr[csr_idx];
                end
                `F3_CSRRSI: begin
                  x[rd] <= csr[csr_idx];
                  if (csr_imm != 0 && !csr_read_only) csr[csr_idx] <= csr[csr_idx] | csr_imm;
                end
                `F3_CSRRCI: begin
                  x[rd] <= csr[csr_idx];
                  if (csr_imm != 0 && !csr_read_only) csr[csr_idx] <= csr[csr_idx] & (~csr_imm);
                end
`ifdef VSIM
                3'b000: begin
                  $display("Finish with EBREAK/ECALL");
                  $finish;
                end
`endif
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
          state <= WAIT_DECODE;
        end
        WAIT_DECODE: begin
          state <= EXECUTE;
        end
        WAIT_READ: begin
          pc <= pc;
          do_decode <= '0;
          state <= WAIT_L;
        end
        WAIT_L: begin
          instret <= instret + 1'b1;
          state <= EXECUTE;
          //if (ex_opcode == `OP_L)
          unique case (ex_f3)
            `F3_LB: begin
              unique case (full_addr_o[1:0])
                2'b00: begin
                  x[ex_rd] <= {{24{data_i[7]}}, data_i[7:0]};
                end
                2'b01: begin
                  x[ex_rd] <= {{24{data_i[15]}}, data_i[15:8]};
                end
                2'b10: begin
                  x[ex_rd] <= {{24{data_i[23]}}, data_i[23:16]};
                end
                2'b11: begin
                  x[ex_rd] <= {{24{data_i[31]}}, data_i[31:24]};
                end
                default: ;
              endcase
            end
            `F3_LH: begin
              unique case (full_addr_o[1:0])
                2'b00: begin
                  x[ex_rd] <= {{16{data_i[15]}}, data_i[15:0]};
                end
                2'b01: begin
                  x[ex_rd] <= {{16{data_i[23]}}, data_i[23:8]};
                end
                2'b10: begin
                  x[ex_rd] <= {{16{data_i[31]}}, data_i[31:16]};
                end
                2'b11: begin
                  assert (0 && |"Illegal LH");
                end
                default: ;
              endcase
            end
            `F3_LW: begin
              x[ex_rd] <= data_i;
            end
            `F3_LBU: begin
              unique case (full_addr_o[1:0])
                2'b00: begin
                  x[ex_rd] <= {{24'b0}, data_i[7:0]};
                end
                2'b01: begin
                  x[ex_rd] <= {{24'b0}, data_i[15:8]};
                end
                2'b10: begin
                  x[ex_rd] <= {{24'b0}, data_i[23:16]};
                end
                2'b11: begin
                  x[ex_rd] <= {{24'b0}, data_i[31:24]};
                end
                default: ;
              endcase
            end
            `F3_LHU: begin
              unique case (full_addr_o[1:0])
                2'b00: begin
                  x[ex_rd] <= {{16'b0}, data_i[15:0]};
                end
                2'b01: begin
                  x[ex_rd] <= {{16'b0}, data_i[23:8]};
                end
                2'b10: begin
                  x[ex_rd] <= {{16'b0}, data_i[31:16]};
                end
                2'b11: begin
                  assert (0 && |"Illegal LHU");
                end
                default: ;
              endcase
            end
            default: begin
            end
          endcase  // OP_L f3
          //end
        end
        default: begin
        end
      endcase  // state
    end
    x[0] <= '0;  // hardwire to 0
    csr[CYCLE] <= cycle_time[31:0];
    csr[CYCLE_H] <= cycle_time[63:32];
    csr[TIME] <= cycle_time[31:0];
    csr[TIME_H] <= cycle_time[63:32];
    csr[INSTRET] <= instret[31:0];
    csr[INSTRET_H] <= instret[63:32];
  end


`ifdef DEBUG
  always_ff @(posedge clk, negedge rst_n) begin : debug
    if (!rst_n) begin
    end else begin
      `PRINT_STEP
      unique case (state)
        EXECUTE: begin
          unique case (opcode)
            `OP_LUI: begin
              `PRINT_U_TYPE
            end
            `OP_AUIPC: begin
              `PRINT_U_TYPE
            end
            `OP_JAL: begin
              `PRINT_JAL
              `PRINT_J_TYPE
            end
            `OP_JALR: begin
              `PRINT_JALR
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
        WAIT_L: begin
          `PRINT_I_TYPE_2
        end
        default: begin
        end
      endcase
    end
    `PRINT_X
  end
`endif

endmodule
