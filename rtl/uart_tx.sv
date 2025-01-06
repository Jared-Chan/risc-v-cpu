module uart_tx #(
    parameter int BaudRate = 9600,
    parameter bit ParityBit = 0,
    parameter int DataBitsSizeInt = 8,
    parameter bit StopBitsSize = 1,
    parameter int ClockFreqHz = 10000000
) (
    input logic clk,
    input logic rst_n,
    input logic [DataBitsSizeInt - 1:0] write_data,
    input logic write,
    output logic tx_sig
);
  typedef enum {
    IDLE,
    WAIT_START,
    DATA,
    PARITY,
    STOP,
    XXX
  } tx_state_e;

  tx_state_e tx_state, tx_next;

  localparam int SClkPeriodInt = ClockFreqHz / BaudRate;
  localparam logic [$clog2(SClkPeriodInt):0] SClkPeriod = SClkPeriodInt[$clog2(SClkPeriodInt):0];

  localparam logic [$clog2(
DataBitsSizeInt
)-1:0] DataBitsSize = DataBitsSizeInt[$clog2(
      DataBitsSizeInt
  )-1:0];
  logic [$clog2(DataBitsSizeInt)-1:0] tx_data_cnt;
  logic [$clog2(SClkPeriod):0] tx_clk_cnt;  // need at least 1.5x SClkPeriod

  logic parity;
  assign parity = 0;  // No parity yet

  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) tx_state <= XXX;
    else tx_state <= tx_next;

  always_comb begin
    tx_next = XXX;
    case (tx_state)
      IDLE:
      if (write) tx_next = DATA;
      else tx_next = IDLE;
      DATA:
      if (tx_data_cnt == DataBitsSize) begin
        if (ParityBit) tx_next = PARITY;
        else tx_next = STOP;
      end else tx_next = DATA;
      PARITY: if (tx_clk_cnt == SClkPeriod) tx_next = STOP;
      STOP: if (tx_clk_cnt == SClkPeriod) tx_next = IDLE;
      default: tx_next = XXX;
    endcase
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      tx_data_cnt <= '0;
      tx_clk_cnt <= '0;
      tx_sig <= '1;
    end else begin
      tx_clk_cnt <= tx_clk_cnt + 1'b1;
      case (tx_state)
        IDLE: begin
          if (write) begin
            tx_clk_cnt <= '0;
            tx_sig <= '0;
          end
        end
        DATA: begin
          if (tx_clk_cnt == SClkPeriod) begin
            tx_sig <= write_data[tx_data_cnt];
            tx_data_cnt <= tx_data_cnt + 1'b1;
            tx_clk_cnt <= '0;
          end
        end
        PARITY:
        if (tx_clk_cnt == SClkPeriod) begin
          tx_clk_cnt <= '0;
          tx_sig <= parity;
        end
        STOP: begin
          if (tx_clk_cnt == SClkPeriod) begin
            tx_sig <= '1;
          end
        end
        default: ;
      endcase
    end
  end
endmodule

