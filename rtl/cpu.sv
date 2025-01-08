`include "config.svh"
`include "cpu.svh"

module cpu (
    input logic clk,
    input logic rst_n,

    // Memory
    output logic [31:0] iaddr_o,
    input logic [31:0] idata_i,
    output logic [31:0] addr_o,
    output logic [31:0] wdata_o,
    input logic [31:0] data_i,
    output logic wr_o,
    output logic data_addr_strobe_o

);

  // General-purpose registers
  logic [`XLEN-1:0] x  [`RLEN];

  // Control and Status Registers
  logic [`XLEN-1:0] csr[ 4096];

  logic [`RLEN-1:0] pc;
  assign iaddr_o = pc;

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
      opcode <= idata_i[6:0];

      {r_f7, r_rs2, r_rs1, r_f3, r_rd} <= {
        idata_i[31:25], idata_i[24:20], idata_i[19:15], idata_i[14:12], idata_i[11:7]
      };

      {i_rs1, i_f3, i_rd} <= {idata_i[19:15], idata_i[14:12], idata_i[11:7]};
      i_imm <= {{21{idata_i[31]}}, idata_i[30:25], idata_i[24:21], idata_i[20]};

      {s_rs2, s_rs1, s_f3} <= {idata_i[24:20], idata_i[19:15], idata_i[14:12]};
      s_imm <= {{21{idata_i[31]}}, idata_i[30:25], idata_i[11:8], idata_i[7]};

      {b_rs2, b_rs1, b_f3} <= {idata_i[24:20], idata_i[19:15], idata_i[14:12]};
      b_imm <= {{20{idata_i[31]}}, idata_i[7], idata_i[30:25], idata_i[11:8], 1'b0};

      {u_rd} <= {idata_i[11:7]};
      u_imm <= {idata_i[31], idata_i[30:20], idata_i[19:12], 12'b0};

      {j_rd} <= {idata_i[11:7]};
      j_imm <= {
        {12{idata_i[31]}}, idata_i[19:12], idata_i[20], idata_i[30:25], idata_i[24:21], 1'b0
      };
      {csr_rs1, csr_f3, csr_rd} <= {idata_i[19:15], idata_i[14:12], idata_i[11:7]};
      csr_imm <= {27'b0, idata_i[19:15]};
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
      wr_o <= '0;
      data_addr_strobe_o <= '0;
      cycle_time <= '0;
      instret <= '0;
    end else begin

      pc <= pc + 4;
      do_decode <= '1;
      wr_o <= 0;
      data_addr_strobe_o <= '0;
      cycle_time <= cycle_time + 1;

      unique case (state)
        EXECUTE: begin
          instret <= instret + 1;
          unique case (opcode)
            `OP_LUI: begin
              x[u_rd] <= u_imm;
            end
            `OP_AUIPC: begin
              x[u_rd] <= dec_pc + u_imm;
            end
            `OP_JAL: begin
              x[j_rd] <= dec_pc + 4;
              if (j_imm != dec_pc + 4) begin
                pc <= pc + j_imm;
                do_decode <= '0;
                state <= WAIT_PC;
              end
              // else pc = pc + 4 is valid
              // should check addr_o alignment
            end
            `OP_JALR: begin
              x[i_rd] <= dec_pc + 4;
              // should check addr_o alignment
              if (((i_imm + x[i_rs1]) & 32'hFFFFFFFE) != dec_pc + 4) begin
                pc <= (i_imm + x[i_rs1]) & 32'hFFFFFFFE;
                do_decode <= '0;
                state <= WAIT_PC;
              end
            end
            `OP_B: begin
              unique case (b_f3)
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
              data_addr_strobe_o <= '1;
              addr_o <= x[i_rs1] + i_imm;
              ex_opcode <= opcode;
              ex_i_f3 <= i_f3;
              ex_i_rd <= i_rd;

              instret <= instret;
              pc <= pc;
              do_decode <= '0;
              state <= WAIT_READ;
            end
            `OP_S: begin
              data_addr_strobe_o <= '1;
              addr_o <= x[s_rs1] + s_imm;
              ex_opcode <= opcode;
              ex_s_f3 <= s_f3;
              ex_s_rs2 <= s_rs2;

              instret <= instret;
              pc <= pc;
              do_decode <= '0;
              state <= WAIT_READ;
            end
            `OP_RI: begin
              unique case (i_f3)
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
              unique case (r_f3)
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
              unique case (csr_f3)
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
            unique case (ex_i_f3)
              `F3_LB: begin
                x[ex_i_rd] <= {{24{data_i[7]}}, data_i[7:0]};
              end
              `F3_LH: begin
                x[ex_i_rd] <= {{16{data_i[15]}}, data_i[15:0]};
              end
              `F3_LW: begin
                x[ex_i_rd] <= data_i;
              end
              `F3_LBU: begin
                x[ex_i_rd] <= {{24'b0}, data_i[7:0]};
              end
              `F3_LHU: begin
                x[ex_i_rd] <= {{16'b0}, data_i[15:0]};
              end
              default: begin
              end
            endcase  // OP_L f3
          else if (ex_opcode == `OP_S) begin
            wr_o <= '1;
            data_addr_strobe_o <= '1;
            unique case (ex_s_f3)
              `F3_SB: begin
                wdata_o <= {data_i[31:8], x[ex_s_rs2][7:0]};
              end
              `F3_SH: begin
                wdata_o <= {data_i[31:16], x[ex_s_rs2][15:0]};
              end
              `F3_SW: begin
                wdata_o <= x[ex_s_rs2];
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
    //`PRINT_X
  end
`endif

endmodule
