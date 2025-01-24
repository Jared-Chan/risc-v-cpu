`include "config.svh"
`include "cpu.svh"

module cpu #(
    parameter int ClockFreqHz = 10000000
) (
    input logic clk,
    input logic rst_n,

`ifdef ZMMUL
    input logic clk_mul,
`endif

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

  localparam int CyclesPerUS = ClockFreqHz / 1_000_000;
  localparam int USPerCycle = 1_000_000 / ClockFreqHz;

  // General-purpose registers
  logic [`XLEN-1:0] x[`RLEN];
  logic [`XLEN-1:0] x_rs1;
  logic [`XLEN-1:0] x_rs2;

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
`ifdef PRIV
    MISA,
    MSTATUS,
    MSTATUS_H,
    MTVEC,
    MIE,
    MIP,
    MSCRATCH,
    MEPC,
    MCAUSE,
    MTVAL,
    XIMPL,  // 0 is returned
`endif
    XSUPPORT  // unsupported CSR
  } csr_e;

  // Control and Status Registers
`ifdef PRIV
  logic [`XLEN-1:0] csr[18];
  logic [63:0] mtimecmp;
`else
  logic [`XLEN-1:0] csr[7];
`endif
  logic [63:0] mtime;

  // Cycle and Time counters
  logic [63:0] cycle;
  logic [31:0] clk_cnt;
  // Instructions retired
  logic [63:0] instret;

  /* Decode */
  logic [6:0] opcode;

  logic [6:0] f7;
  logic [6:0] f7_reg;
  logic [4:0] rs2;
  logic [4:0] rs2_reg;
  logic signed [31:0] rs2_s;
  logic [4:0] rs1;
  logic [4:0] rs1_reg;
  logic signed [31:0] rs1_s;
  logic [2:0] f3;
  logic [2:0] f3_reg;
  logic [4:0] rd;
  logic [4:0] rd_reg;

  // I-type
  logic [31:0] i_imm;
  logic [31:0] i_imm_reg;
  logic signed [31:0] i_imm_s;
  logic signed [31:0] i_imm_reg_s;
  logic [4:0] i_shamt;
  logic [4:0] i_shamt_reg;
  logic [6:0] i_f7;
  assign i_shamt = i_imm[4:0];
  assign i_f7 = i_imm[11:5];
  assign i_imm_s = i_imm;
  assign i_imm_reg_s = i_imm_reg;

  // S-type
  logic [31:0] s_imm;
  logic [31:0] s_imm_reg;
  logic [31:0] s_addr;
  logic [31:0] s_addr_reg;

  // B-type (~S)
  logic [31:0] b_imm;

  // U-type
  logic [31:0] u_imm;
  logic [31:0] u_imm_reg;

  // J-type
  logic [31:0] j_imm;
  logic [31:0] j_imm_reg;

  // CSR
  logic [31:0] csr_imm;
  assign csr_imm = {27'b0, rs1_reg};
  logic [11:0] csr_src_dest;
  csr_e csr_idx;
  logic csr_read_only;


  logic [31:0] dec_pc;  // pc of decoded instruction
  logic [31:0] branch_dest;
  logic [31:0] auipc_result;
  logic [31:0] j_rd;
  logic [31:0] j_dest;
  logic [31:0] load_addr;

  always_comb begin
    {f7, rs2, rs1, f3, rd} = {
      idata_i[31:25], idata_i[24:20], idata_i[19:15], idata_i[14:12], idata_i[11:7]
    };

    i_imm = {{21{idata_i[31]}}, idata_i[30:25], idata_i[24:21], idata_i[20]};

    s_imm = {{21{idata_i[31]}}, idata_i[30:25], idata_i[11:8], idata_i[7]};

    b_imm = {{20{idata_i[31]}}, idata_i[7], idata_i[30:25], idata_i[11:8], 1'b0};

    u_imm = {idata_i[31], idata_i[30:20], idata_i[19:12], 12'b0};

    j_imm = {{12{idata_i[31]}}, idata_i[19:12], idata_i[20], idata_i[30:25], idata_i[24:21], 1'b0};

    // Avoid data hazard
    if (state == EXECUTE && (opcode == `OP_LUI || opcode == `OP_AUIPC ||
        opcode == `OP_JAL || opcode == `OP_JALR || opcode == `OP_RI ||
        opcode == `OP_RR || opcode == `OP_SYS)) begin
      x_rs1  = rd_reg == rs1 ? x_rd : x[rs1];
      x_rs2  = rd_reg == rs2 ? x_rd : x[rs2];
      s_addr = rd_reg == rs1 ? x_rd + s_imm : x[rs1] + s_imm;
      rs1_s  = rd_reg == rs1 ? x_rd : x[rs1];
      rs2_s  = rd_reg == rs2 ? x_rd : x[rs2];
    end else begin
      x_rs1  = x[rs1];
      x_rs2  = x[rs2];
      s_addr = x[rs1] + s_imm;
      rs2_s  = x[rs2];
      rs1_s  = x[rs1];
    end
  end

  always_ff @(posedge clk, negedge rst_n) begin : decode
    if (!rst_n) opcode <= 7'b0;
    else if (do_decode) begin
      // pc is the pc of the next instruction
      // pc - 4 is the pc of the instruction being decoded
      dec_pc <= pc - 4;

`ifdef PRIV
      if (s_addr[31:24] == `MREG_PREFIX && idata_i[6:0] == `OP_S) opcode <= `OP_S_MREG;
      else if (s_addr[31:24] == `MREG_PREFIX && idata_i[6:0] == `OP_L) opcode <= `OP_L_MREG;
      else
`endif
          opcode <= idata_i[6:0];

      branch_dest <= pc - 4 + b_imm;
      auipc_result <= pc - 4 + u_imm;

      rs1_reg <= rs1;
      rs2_reg <= rs2;
      rd_reg <= rd;
      f7_reg <= (idata_i[6:0] == `OP_RI && f3 == `F3_ADDSUB) ? `F7_ADD : f7;
      f3_reg <= f3;
      u_imm_reg <= u_imm;
      s_imm_reg <= s_imm;
      i_imm_reg <= i_imm;
      j_imm_reg <= j_imm;
      i_shamt_reg <= i_shamt;
      j_rd <= pc;  // dec_pc + 4
      j_dest <= idata_i[6:0] == `OP_JAL ? pc - 4 + j_imm : (i_imm + x_rs1) & 32'hFFFFFFFE;
      load_addr <= x_rs1 + i_imm;
      s_addr_reg <= s_addr;

      alu_operand_1 <= f3 == `F3_SLT ? rs1_s : x_rs1;
      alu_operand_2 <= idata_i[6:0] == `OP_RR ?
          (f3 == `F3_SLT ? rs2_s : x_rs2) :
          (f3 == `F3_SLT ? i_imm_s :
          ((f3 == `F3_SLL || f3 == `F3_SR) ? {27'b0, i_shamt} : i_imm));

`ifdef ZMMUL
      alu_operand_1_signed <= (f3 == `F3_MULHU || f3 == `F3_MUL) ? '0 : '1;
      alu_operand_2_signed <= (f3 == `F3_MULH) ? '1 : '0;
`endif


      comp_operand_1 <= x_rs1;
      comp_operand_2 <= x_rs2;

      csr_src_dest <= idata_i[31:20];
      case (idata_i[31:20])
        `CSR_CYCLE: csr_idx <= CYCLE;
        `CSR_CYCLE_H: csr_idx <= CYCLE_H;
        `CSR_TIME: csr_idx <= TIME;
        `CSR_TIME_H: csr_idx <= TIME_H;
        `CSR_INSTRET: csr_idx <= INSTRET;
        `CSR_INSTRET_H: csr_idx <= INSTRET_H;
`ifdef PRIV
        `CSR_MISA: csr_idx <= MISA;
        `CSR_MSTATUS: csr_idx <= MSTATUS;
        `CSR_MSTATUS_H: csr_idx <= MSTATUS_H;
        `CSR_MTVEC: csr_idx <= MTVEC;
        `CSR_MIE: csr_idx <= MIE;
        `CSR_MIP: csr_idx <= MIP;
        `CSR_MSCRATCH: csr_idx <= MSCRATCH;
        `CSR_MEPC: csr_idx <= MEPC;
        `CSR_MCAUSE: csr_idx <= MCAUSE;
        `CSR_MTVAL: csr_idx <= MTVAL;
        `CSR_MVENDORID: csr_idx <= XIMPL;
        `CSR_MARCHID: csr_idx <= XIMPL;
        `CSR_MIMPID: csr_idx <= XIMPL;
        `CSR_MHARTID: csr_idx <= XIMPL;  // single-core, so 0
        `CSR_MCONFIGPTR: csr_idx <= XIMPL;
`endif
        default: csr_idx <= XSUPPORT;
      endcase
      csr_read_only <= idata_i[31:30] == 2'b11 ? 1'b1 : 1'b0;
    end // if do_decode
    else if (state == WAIT_L || (state == WAIT_MUL && mul_ready)) begin
      // avoid data hazard when there are wait states and the combinational
      // logic couldn't prevent it
      if (ex_rd == rs1_reg) begin
        j_dest <= opcode == `OP_JAL ? dec_pc + j_imm_reg : (i_imm_reg + x_rd) & 32'hFFFFFFFE;
        load_addr <= x_rd + i_imm_reg;
        s_addr_reg <= s_imm_reg + x_rd;
        alu_operand_1 <= f3_reg == `F3_SLT ? x_rd_s : x_rd;
        comp_operand_1 <= x_rd;
      end

      if (ex_rd == rs2_reg) begin
        alu_operand_2 <= opcode == `OP_RR ?
              (f3_reg == `F3_SLT ? x_rd_s : x_rd) :
              (f3_reg == `F3_SLT ? i_imm_reg_s :
              ((f3_reg == `F3_SLL || f3_reg == `F3_SR) ? {27'b0, i_shamt_reg} : i_imm_reg));
        comp_operand_2 <= x_rd;
      end
    end
  end
  /* End Decode */

  /* Comparator */
  logic comp_result;
  logic [`XLEN-1:0] comp_operand_1;
  logic signed [`XLEN-1:0] comp_operand_1_s;
  logic [`XLEN-1:0] comp_operand_2;
  logic signed [`XLEN-1:0] comp_operand_2_s;
  assign comp_operand_1_s = comp_operand_1;
  assign comp_operand_2_s = comp_operand_2;
  always_comb begin
    unique case (f3_reg)
      `F3_BEQ: begin
        if (comp_operand_1 == comp_operand_2) comp_result = '1;
        else comp_result = '0;
      end
      `F3_BNE: begin
        if (comp_operand_1 != comp_operand_2) comp_result = '1;
        else comp_result = '0;
      end
      `F3_BLT: begin
        if (comp_operand_1_s < comp_operand_2_s) comp_result = '1;
        else comp_result = '0;
      end
      `F3_BGE: begin
        if (comp_operand_1_s >= comp_operand_2_s) comp_result = '1;
        else comp_result = '0;
      end
      `F3_BLTU: begin
        if (comp_operand_1 < comp_operand_2) comp_result = '1;
        else comp_result = '0;
      end
      `F3_BGEU: begin
        if (comp_operand_1 >= comp_operand_2) comp_result = '1;
        else comp_result = '0;
      end
      default: begin
        comp_result = '0;
      end
    endcase
  end
  /* End Comparator */

  /* ALU */
  logic [`XLEN-1:0] alu_result;
  logic [`XLEN-1:0] alu_operand_1;
  logic signed [`XLEN-1:0] alu_operand_1_s;
  logic [`XLEN-1:0] alu_operand_2;
  logic signed [`XLEN-1:0] alu_operand_2_s;
  assign alu_operand_1_s = alu_operand_1;
  assign alu_operand_2_s = alu_operand_2;

  always_comb begin
    unique case (f3_reg)
      `F3_ADDSUB: begin
        if (f7_reg == `F7_ADD) alu_result = alu_operand_1 + alu_operand_2;
        else alu_result = alu_operand_1 - alu_operand_2;
      end
      `F3_SLT: begin
        alu_result = alu_operand_1_s < alu_operand_2_s ? 32'h0000_0001 : '0;
      end
      `F3_SLTU: begin
        alu_result = alu_operand_1 < alu_operand_2 ? 32'h0000_0001 : '0;
      end
      `F3_XOR: begin
        alu_result = alu_operand_1 ^ alu_operand_2;
      end
      `F3_OR: begin
        alu_result = alu_operand_1 | alu_operand_2;
      end
      `F3_AND: begin
        alu_result = alu_operand_1 & alu_operand_2;
      end
      `F3_SLL: begin
        alu_result = alu_operand_1 << alu_operand_2;
      end
      `F3_SR: begin
        if (f7_reg == `F7_SRL) alu_result = alu_operand_1 >> alu_operand_2;
        else alu_result = alu_operand_1_s >>> alu_operand_2;
      end
      default: begin
      end
    endcase
  end
  /* End ALU */

`ifdef ZMMUL
  /* Multiplier */
  logic mul_start;
  logic mul_ready;
  logic [31:0] mul_operand_1;
  logic [31:0] mul_operand_2;
  logic alu_operand_1_signed;
  logic alu_operand_2_signed;
  logic mul_operand_1_signed;
  logic mul_operand_2_signed;
  logic [31:0] mul_result_l;
  logic [31:0] mul_result_h;

  mul #(
      .Width(32)
  ) mul_inst (
      .rst_n(rst_n),
      .clk_sys(clk),
      .multiplicand(mul_operand_1),
      .multiplier(mul_operand_2),
      .multiplicand_signed(mul_operand_1_signed),
      .multiplier_signed(mul_operand_2_signed),
      .start(mul_start),

      .clk_mul(clk_mul),
      .ready_sync(mul_ready),
      .result_l(mul_result_l),
      .result_h(mul_result_h)
  );
  /* End multiplier */
`endif

  /* Calculate x[rd] */
  logic [31:0] x_rd;
  logic signed [31:0] x_rd_s;
  assign x_rd_s = x_rd;
  always_comb begin
    x_rd = '0;  // Default
    unique case (state)
      EXECUTE: begin
        unique case (opcode)
          `OP_LUI: begin
            x_rd = u_imm_reg;
          end
          `OP_AUIPC: begin
            x_rd = auipc_result;
          end
          `OP_JAL: begin
            x_rd = j_rd;
          end
          `OP_JALR: begin
            x_rd = j_rd;
          end
          `OP_RI: begin
            x_rd = alu_result;
          end
          `OP_RR: begin
            x_rd = alu_result;
          end
          `OP_SYS: begin
            x_rd = csr[csr_idx];
          end
          default: begin
          end
        endcase  // opcode
      end
`ifdef ZMMUL
      WAIT_MUL: begin
        unique case (ex_f3)
            `F3_MUL: x_rd = mul_result_l;
            default: x_rd = mul_result_h;
        endcase
      end
`endif
      WAIT_L: begin
        unique case (ex_f3)
          `F3_LB: begin
            unique case (full_addr_o[1:0])
              2'b00: begin
                x_rd = {{24{data_i[7]}}, data_i[7:0]};
              end
              2'b01: begin
                x_rd = {{24{data_i[15]}}, data_i[15:8]};
              end
              2'b10: begin
                x_rd = {{24{data_i[23]}}, data_i[23:16]};
              end
              2'b11: begin
                x_rd = {{24{data_i[31]}}, data_i[31:24]};
              end
              default: ;
            endcase
          end
          `F3_LH: begin
            unique case (full_addr_o[1:0])
              2'b00: begin
                x_rd = {{16{data_i[15]}}, data_i[15:0]};
              end
              2'b01: begin
                x_rd = {{16{data_i[23]}}, data_i[23:8]};
              end
              2'b10: begin
                x_rd = {{16{data_i[31]}}, data_i[31:16]};
              end
              2'b11: begin
`ifdef VSIM
                assert (0 && |"Illegal LH");
`endif
              end
              default: ;
            endcase
          end
          `F3_LW: begin
            x_rd = data_i;
          end
          `F3_LBU: begin
            unique case (full_addr_o[1:0])
              2'b00: begin
                x_rd = {{24'b0}, data_i[7:0]};
              end
              2'b01: begin
                x_rd = {{24'b0}, data_i[15:8]};
              end
              2'b10: begin
                x_rd = {{24'b0}, data_i[23:16]};
              end
              2'b11: begin
                x_rd = {{24'b0}, data_i[31:24]};
              end
              default: ;
            endcase
          end
          `F3_LHU: begin
            unique case (full_addr_o[1:0])
              2'b00: begin
                x_rd = {{16'b0}, data_i[15:0]};
              end
              2'b01: begin
                x_rd = {{16'b0}, data_i[23:8]};
              end
              2'b10: begin
                x_rd = {{16'b0}, data_i[31:16]};
              end
              2'b11: begin
`ifdef VSIM
                assert (0 && |"Illegal LHU");
`endif
              end
              default: ;
            endcase
          end
          default: begin
          end
        endcase  // OP_L f3
      end
      default: begin
      end
    endcase  // state
  end
  /* End: Calculate x[rd] */

  /* Execute/Write-back/Memory */
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
`ifdef ZMMUL
    WAIT_MUL,
    WAIT_MUL_START,
    WAIT_MUL_READY,
`endif
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
      cycle <= '0;
      mtime <= '0;
      clk_cnt <= '0;
      instret <= '0;
      byte_en_o <= 4'b1111;

`ifdef PRIV
      csr[MISA] <= {`MISA_MXL, 4'b0, `MISA_RV32I};
      csr[MIP] <= '0;
      csr[MIE] <= '0;
      csr[MSTATUS][`MSTATUS_BITS_MIE] <= 1'b0;
      csr[MCAUSE] <= '0;  // do not distinguish reset conditions
      // no MPRV
      // MBE is always 0
      mtimecmp <= '1;
`endif

`ifdef ZMMUL
        mul_start <= '0;
`endif

    end else begin // rst_n

      pc <= pc + 32'h4;
      do_decode <= '1;
      wr_o <= 0;
      data_addr_strobe_o <= '0;
      byte_en_o <= 4'b1111;

`ifdef ZMMUL
        mul_start <= '0;
`endif

      // begin: cycle, time, and instret
      cycle <= cycle + 1'b1;
      clk_cnt <= clk_cnt + 1'b1;
      if (CyclesPerUS > 0 && clk_cnt == CyclesPerUS - 1) begin
        clk_cnt <= '0;
        mtime   <= mtime + 1'b1;
      end
      if (CyclesPerUS == 0 && USPerCycle > 0) begin
        mtime <= mtime + {32'b0, USPerCycle};
      end
      // end: cycle, time, and instret

`ifdef PRIV
      // begin: interrupt
      // set interrupt pending
      if (mtime > mtimecmp) csr[MIP][`MIP_BITS_MTIP] <= 1'b1;
      else csr[MIP][`MIP_BITS_MTIP] <= 1'b0;
      // handle pending interrupts
      if (csr[MSTATUS][`MSTATUS_BITS_MIE] && (csr[MIE] & csr[MIP]) > 0) begin
        csr[MCAUSE][`MCAUSE_BITS_INTERRUPT] <= 1'b1;
        csr[MEPC] <= dec_pc;
        state <= WAIT_PC;
        do_decode <= '0;
        csr[MSTATUS][`MSTATUS_BITS_MIE] <= 1'b0;
        csr[MSTATUS][`MSTATUS_BITS_MPIE] <= csr[MSTATUS][`MSTATUS_BITS_MIE];
        // no setting MPP since only M-mode is supported
        if (csr[MIE][`MIE_BITS_MEIE] & csr[MIP][`MIP_BITS_MEIP]) begin
`ifdef VSIM
          assert (0 && |"MEIE not implemented");
`endif
        end else if (csr[MIE][`MIE_BITS_MSIE] & csr[MIP][`MIP_BITS_MSIP]) begin
`ifdef VSIM
          assert (0 && |"MSIE not implemented");
`endif
        end else if (csr[MIE][`MIE_BITS_MTIE] & csr[MIP][`MIP_BITS_MTIP]) begin
          csr[MCAUSE][`MCAUSE_BITS_EXCEPTION_CODE] <= `EXCEPTION_CODE_M_TIMER;
          if (csr[MTVEC][`MTVEC_BITS_MODE] == 2'b0) pc <= {csr[MTVEC][`MTVEC_BITS_BASE], 2'b0};
          else pc <= {csr[MTVEC][`MTVEC_BITS_BASE], 2'b0} + ({1'b0, `EXCEPTION_CODE_M_TIMER} << 2);
        end
      end  // end: interrupt
      else begin  // no pending interrupt to handle
`endif
        unique case (state)
          EXECUTE: begin
            instret <= instret + 1'b1;
            unique case (opcode)
              `OP_LUI: begin
                x[rd_reg] <= x_rd;
              end
              `OP_AUIPC: begin
                x[rd_reg] <= x_rd;
              end
              `OP_JAL: begin
                x[rd_reg] <= x_rd;
                pc <= j_dest;
                do_decode <= '0;
                state <= WAIT_PC;
                // else pc = pc + 4 is valid
                // should check addr alignment
              end
              `OP_JALR: begin
                x[rd_reg] <= x_rd;
                // should check addr alignment
                pc <= j_dest;
                do_decode <= '0;
                state <= WAIT_PC;
              end
              `OP_B: begin
                if (comp_result) begin
                  pc <= branch_dest;
                  do_decode <= '0;
                  state <= WAIT_PC;
                end
              end
`ifdef PRIV
              `OP_L_MREG: begin
                unique case (load_addr[7:0])
                  `MTIMECMP_ADDR_8: x[rd_reg] <= mtimecmp[31:0];
                  `MTIMECMP_H_ADDR_8: x[rd_reg] <= mtimecmp[63:32];
                  `MTIME_ADDR_8: x[rd_reg] <= mtime[31:0];
                  `MTIME_H_ADDR_8: x[rd_reg] <= mtime[63:32];
                  default: begin
                  end
                endcase
              end
              `OP_S_MREG: begin
                unique case (s_addr_reg[7:0])
                  `MTIMECMP_ADDR_8: mtimecmp[31:0] <= x[rs2_reg];
                  `MTIMECMP_H_ADDR_8: mtimecmp[63:32] <= x[rs2_reg];
                  `MTIME_ADDR_8: mtime[31:0] <= x[rs2_reg];
                  `MTIME_H_ADDR_8: mtime[63:32] <= x[rs2_reg];
                  default: begin
                  end
                endcase
              end
`endif
              `OP_L: begin
                data_addr_strobe_o <= '1;
                full_addr_o <= load_addr;
                ex_opcode <= opcode;
                ex_f3 <= f3_reg;
                ex_rd <= rd_reg;

                instret <= instret;
                pc <= pc;
                do_decode <= '0;
                state <= WAIT_READ;
              end
              `OP_S: begin
                data_addr_strobe_o <= '1;
                full_addr_o <= s_addr_reg;
                wr_o <= '1;

                unique case (f3_reg)
                  `F3_SB: begin
                    unique case (s_addr_reg[1:0])
                      2'b00: begin
                        wdata_o   <= {24'b0, x[rs2_reg][7:0]};
                        byte_en_o <= 4'b0001;
                      end
                      2'b01: begin
                        wdata_o   <= {16'b0, x[rs2_reg][7:0], 8'b0};
                        byte_en_o <= 4'b0010;
                      end
                      2'b10: begin
                        wdata_o   <= {8'b0, x[rs2_reg][7:0], 16'b0};
                        byte_en_o <= 4'b0100;
                      end
                      2'b11: begin
                        wdata_o   <= {x[rs2_reg][7:0], 24'b0};
                        byte_en_o <= 4'b1000;
                      end
                      default: ;
                    endcase
                  end
                  `F3_SH: begin
                    unique case (s_addr_reg[1:0])
                      2'b00: begin
                        wdata_o   <= {16'b0, x[rs2_reg][15:0]};
                        byte_en_o <= 4'b0011;
                      end
                      2'b01: begin
                        wdata_o   <= {8'b0, x[rs2_reg][15:0], 8'b0};
                        byte_en_o <= 4'b0110;
                      end
                      2'b10: begin
                        wdata_o   <= {x[rs2_reg][15:0], 16'b0};
                        byte_en_o <= 4'b1100;
                      end
                      2'b11: begin
`ifdef VSIM
                        assert (0 && |"Illegal SH");
`endif
                        wdata_o   <= '0;
                        byte_en_o <= 4'b0000;
                      end
                      default: ;
                    endcase
                  end
                  `F3_SW: begin
                    wdata_o <= x[rs2_reg];
                  end
                  default: begin
                  end
                endcase  // OP_S f3
              end
              `OP_RI: begin
                x[rd_reg] <= x_rd;
              end
              `OP_RR: begin
`ifdef ZMMUL
                if (f7_reg == `F7_MUL) begin
                    mul_operand_1 <= alu_operand_1;
                    mul_operand_2 <= alu_operand_2;
                    mul_operand_1_signed <= alu_operand_1_signed;
                    mul_operand_2_signed <= alu_operand_2_signed;
                    ex_f3 <= f3_reg;
                    ex_rd <= rd_reg;
                    instret <= instret;
                    pc <= pc;
                    do_decode <= '0;
                    if (mul_ready) begin
                        mul_start <= '1;
                        state <= WAIT_MUL_START;
                    end
                    else state <= WAIT_MUL_READY;
                end
                else begin
`endif
                x[rd_reg] <= x_rd;
`ifdef ZMMUL
                end
`endif
              end
              `OP_F: begin
              end
              `OP_SYS: begin
`ifdef VSIM
                if (csr_idx == XSUPPORT) assert (0 && |"Accessing unsupported CSR");
`endif
                unique case (f3_reg)
                  `F3_CSRRW: begin
                    if (!csr_read_only) csr[csr_idx] <= x[rs1_reg];
                    if (rd_reg != 0) x[rd_reg] <= x_rd;
                  end
                  `F3_CSRRS: begin
                    x[rd_reg] <= x_rd;
                    if (rs1_reg != 0 && !csr_read_only) csr[csr_idx] <= csr[csr_idx] | x[rs1_reg];
                  end
                  `F3_CSRRC: begin
                    x[rd_reg] <= x_rd;
                    if (rs1_reg != 0 && !csr_read_only)
                      csr[csr_idx] <= csr[csr_idx] & (~x[rs1_reg]);
                  end
                  `F3_CSRRWI: begin
                    if (!csr_read_only) csr[csr_idx] <= csr_imm;
                    if (rd_reg != 0) x[rd_reg] <= x_rd;
                  end
                  `F3_CSRRSI: begin
                    x[rd_reg] <= x_rd;
                    if (csr_imm != 0 && !csr_read_only) csr[csr_idx] <= csr[csr_idx] | csr_imm;
                  end
                  `F3_CSRRCI: begin
                    x[rd_reg] <= x_rd;
                    if (csr_imm != 0 && !csr_read_only) csr[csr_idx] <= csr[csr_idx] & (~csr_imm);
                  end
                  `F3_PRIV: begin
`ifdef PRIV
                    unique case (i_imm_reg[11:0])
                      `F12_MRET: begin
                        pc <= csr[MEPC];
                        state <= WAIT_PC;
                        do_decode <= '0;
                        csr[MSTATUS][`MSTATUS_BITS_MIE] <= csr[MSTATUS][`MSTATUS_BITS_MPIE];
                      end
`ifdef ENV_FINISH
                      default: begin
                        $display("Finish with EBREAK/ECALL");
                        $finish;
                      end
`else
                      `F12_ECALL: begin
                        instret <= instret;
                        csr[MCAUSE][`MCAUSE_BITS_INTERRUPT] <= 1'b0;
                        csr[MEPC] <= dec_pc;
                        state <= WAIT_PC;
                        do_decode <= '0;
                        csr[MSTATUS][`MSTATUS_BITS_MIE] <= 1'b0;
                        csr[MSTATUS][`MSTATUS_BITS_MPIE] <= csr[MSTATUS][`MSTATUS_BITS_MIE];
                        csr[MCAUSE][`MCAUSE_BITS_EXCEPTION_CODE] <= `E_CODE_M_ECALL;
                        if (csr[MTVEC][`MTVEC_BITS_MODE] == 2'b0)
                          pc <= {csr[MTVEC][`MTVEC_BITS_BASE], 2'b0};
                        else
                          pc <= {csr[MTVEC][`MTVEC_BITS_BASE], 2'b0} + ({1'b0, `E_CODE_M_ECALL} << 2);
                      end
                      `F12_EBREAK: begin
                        instret <= instret;
                        csr[MCAUSE][`MCAUSE_BITS_INTERRUPT] <= 1'b0;
                        csr[MEPC] <= dec_pc;
                        state <= WAIT_PC;
                        do_decode <= '0;
                        csr[MSTATUS][`MSTATUS_BITS_MIE] <= 1'b0;
                        csr[MSTATUS][`MSTATUS_BITS_MPIE] <= csr[MSTATUS][`MSTATUS_BITS_MIE];
                        csr[MCAUSE][`MCAUSE_BITS_EXCEPTION_CODE] <= `E_CODE_EBREAK;
                        if (csr[MTVEC][`MTVEC_BITS_MODE] == 2'b0)
                          pc <= {csr[MTVEC][`MTVEC_BITS_BASE], 2'b0};
                        else
                          pc <= {csr[MTVEC][`MTVEC_BITS_BASE], 2'b0} + ({1'b0, `E_CODE_EBREAK} << 2);
                      end
                      default: ;
`endif // ifdef ENV_FINISH
                    endcase
`else // ifdef PRIV
                    $display("Finish with EBREAK/ECALL");
                    $finish;
`endif // ifdef PRIV

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
`ifdef ZMMUL
          WAIT_MUL_READY: begin
            pc <= pc;
            do_decode <= '0;
            if (mul_ready) begin
                mul_start <= '1;
                state <= WAIT_MUL_START;
            end
            else begin
                state <= WAIT_MUL_READY;
            end
          end
          WAIT_MUL_START: begin
            pc <= pc;
            do_decode <= '0;
            if (~mul_ready) begin
                state <= WAIT_MUL;
                mul_start <= '0;
            end
            else begin
                state <= WAIT_MUL_START;
                mul_start <= '1;
            end
          end
          WAIT_MUL: begin
            if (mul_ready) begin
                instret <= instret + 1'b1;
                x[ex_rd] <= x_rd;
                state <= EXECUTE;
            end
            else begin
                pc <= pc;
                do_decode <= '0;
                state <= WAIT_MUL;
            end
          end
`endif
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
            x[ex_rd] <= x_rd;
            //end
          end
          default: begin
          end
        endcase  // state
`ifdef PRIV
      end // if interrupt
`endif
    end
    x[0] <= '0;  // hardwire to 0
    // read-only csrs
    csr[CYCLE] <= cycle[31:0];
    csr[CYCLE_H] <= cycle[63:32];
    csr[TIME] <= mtime[31:0];
    csr[TIME_H] <= mtime[63:32];
    csr[INSTRET] <= instret[31:0];
    csr[INSTRET_H] <= instret[63:32];
`ifdef PRIV
    // read-only 0 csrs
    csr[MSTATUS][`MSTATUS_BITS_MPRV] <= 1'b0;  // U-mode not supported
    csr[MSTATUS][`MSTATUS_BITS_MXR] <= 1'b0;  // S-mode not supported
    csr[MSTATUS][`MSTATUS_BITS_SUM] <= 1'b0;  // S-mode not supported
    csr[MSTATUS][`MSTATUS_BITS_UBE] <= 1'b0;  // U-mode not supported
    csr[MSTATUS_H][`MSTATUS_H_BITS_SBE] <= 1'b0;  // S-mode not supported
    csr[MSTATUS_H][`MSTATUS_H_BITS_MBE] <= 1'b0;  // Only little-endian
    csr[MSTATUS][`MSTATUS_BITS_TW] <= 1'b0;  // U-mode and S-mode not supported
    csr[MSTATUS][`MSTATUS_BITS_TSR] <= 1'b0;  // S-mode not supported
    csr[MSTATUS][`MSTATUS_BITS_FS] <= 2'b0;  // extension not supported
    csr[MSTATUS][`MSTATUS_BITS_VS] <= 2'b0;  // extension not supported
    csr[MSTATUS][`MSTATUS_BITS_XS] <= 2'b0;  // extension not supported
    csr[MSTATUS][`MSTATUS_BITS_SD] <= 1'b0;  // extension not supported
    csr[MIE][`MIE_BITS_SEIE] <= 1'b0;  // S-mode not supported
    csr[MIE][`MIE_BITS_STIE] <= 1'b0;  // S-mode not supported
    csr[MIE][`MIE_BITS_SSIE] <= 1'b0;  // S-mode not supported
    csr[MIE][`MIE_BITS_LCOFIE] <= 1'b0;  // Sscofpmf not supported
    csr[MIP][`MIP_BITS_SEIP] <= 1'b0;  // S-mode not supported
    csr[MIP][`MIP_BITS_STIP] <= 1'b0;  // S-mode not supported
    csr[MIP][`MIP_BITS_SSIP] <= 1'b0;  // S-mode not supported
    csr[MIP][`MIP_BITS_LCOFIP] <= 1'b0;  // Sscofpmf not supported
    // warl csr
    csr[MISA] <= {`MISA_MXL, 4'b0, `MISA_RV32I};
    // 0 returned csr
    csr[XIMPL] <= '0;
`endif
  end

`ifdef DEBUG_HEARTBEAT
  logic [63:0] debug_counter = 0;
  always_ff @(posedge clk) begin
    debug_counter <= debug_counter + 1'b1;
    if (debug_counter % 10000000 == 0) begin
      `TRACE
    end
    /*
    if (pc == csr[MTVEC] + 8) begin
      // +8 or dec_pc would work too
      $display("\n=============================\nTRAP!!!\n=============================\n");
      `TRACE
    end
    */
  end
`endif

`ifdef DEBUG
  always_ff @(posedge clk, negedge rst_n) begin : debug
    if (!rst_n) begin
    end else begin
      `TRACE
      /*
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
    */
    end
    `PRINT_X
  end
`endif

endmodule
