module uart_rx #(
    parameter int BaudRate = 9600,
    parameter bit ParityBit = 0,
    parameter int DataBitsSizeInt = 8,
    parameter bit StopBitsSize = 1,
    parameter int BufferSizeInt = 64,
    parameter int ClockFreqHz = 10000000
) (
    input logic clk,
    input logic rst_n,
    output logic ready,
    input logic rx_sig,
    output logic [$clog2(BufferSizeInt)-1:0] next_rx_data_idx,

    ref logic [7:0] read_buffer[BufferSizeInt]
);
  typedef enum {
    IDLE,
    WAIT_START,
    DATA,
    PARITY,
    STOP,
    XXX
  } rx_state_e;

  rx_state_e rx_state, rx_next;

  localparam logic [$clog2(
BufferSizeInt
)-1:0] BufferSize = BufferSizeInt[$clog2(
      BufferSizeInt
  )-1:0];
  localparam int SClkPeriodInt = ClockFreqHz / BaudRate;
  localparam logic [$clog2(SClkPeriodInt):0] SClkPeriod = SClkPeriodInt[$clog2(SClkPeriodInt):0];

  localparam logic [$clog2(
DataBitsSizeInt
)-1:0] DataBitsSize = DataBitsSizeInt[$clog2(
      DataBitsSizeInt
  )-1:0];
  logic [$clog2(DataBitsSizeInt)-1:0] rx_data_cnt;
  logic [$clog2(SClkPeriod):0] rx_clk_cnt;  // need at least 1.5x SClkPeriod

  logic parity;

  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) rx_state <= XXX;
    else rx_state <= rx_next;

  always_comb begin
    rx_next = XXX;
    case (rx_state)
      IDLE:
      if (rx_sig == 0) rx_next = WAIT_START;
      else rx_next = IDLE;
      WAIT_START: begin
        if (rx_clk_cnt == SClkPeriod + SClkPeriod / 2) begin
          rx_next = DATA;
        end else if (rx_sig == 1 && rx_clk_cnt < SClkPeriod / 2) begin
          // avoid spurious pulses
          rx_next = IDLE;
        end
      end
      DATA:
      if (rx_data_cnt == DataBitsSize) begin
        if (ParityBit) rx_next = PARITY;
        else rx_next = STOP;
      end else rx_next = DATA;
      PARITY: if (rx_clk_cnt == SClkPeriod) rx_next = STOP;
      STOP: if (rx_clk_cnt == SClkPeriod) rx_next = IDLE;
      default: rx_next = XXX;
    endcase
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      next_rx_data_idx <= '0;
      rx_data_cnt <= '0;
      ready <= '0;
      rx_clk_cnt <= '0;
    end else begin
      rx_clk_cnt <= rx_clk_cnt + 1'b1;
      case (rx_state)
        IDLE: begin
          if (rx_sig == 1'b0) begin
            ready <= '0;
            rx_clk_cnt <= '0;
          end
        end
        WAIT_START: begin
          // Sample in the middle of a period
          if (rx_clk_cnt == SClkPeriod + SClkPeriod / 2) rx_clk_cnt <= '0;
        end
        DATA: begin
          if (rx_clk_cnt == SClkPeriod) begin
            rx_clk_cnt <= '0;
            read_buffer[next_rx_data_idx][rx_data_cnt] <= rx_sig;
            rx_data_cnt <= rx_data_cnt + 1'b1;
          end
        end
        PARITY:
        if (rx_clk_cnt == SClkPeriod) begin
          rx_clk_cnt <= '0;
          parity <= rx_sig;
        end
        STOP: begin
          if (rx_clk_cnt == SClkPeriod) begin
            ready <= '1;
            if (next_rx_data_idx == BufferSize - 1'b1) next_rx_data_idx <= '0;
            else next_rx_data_idx <= next_rx_data_idx + 1'b1;
          end
        end
        default: ;
      endcase
    end
  end
endmodule
