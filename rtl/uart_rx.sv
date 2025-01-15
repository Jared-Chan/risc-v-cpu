module uart_rx #(
    parameter int BaudRate = 115200,
    parameter bit ParityBit = 0,
    parameter byte DataBitsSize = 8,
    parameter bit StopBitsSize = 1,
    parameter byte BufferSize = 128,
    parameter int ClockFreqHz = 10000000
) (
    input logic clk,
    input logic rst_n,
    input logic rx_sig,

    output logic write_req,
    output logic [7:0] data
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

  localparam int SClkPeriod = ClockFreqHz / BaudRate;

  logic [7:0] rx_data_cnt;
  logic [31:0] rx_clk_cnt;  // need at least 1.5x SClkPeriod

  logic parity;

  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) rx_state <= IDLE;
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
        end else rx_next = WAIT_START;
      end
      DATA:
      if (rx_data_cnt == DataBitsSize) begin
        if (ParityBit) rx_next = PARITY;
        else rx_next = STOP;
      end else rx_next = DATA;
      PARITY:
      if (rx_clk_cnt == SClkPeriod) rx_next = STOP;
      else rx_next = PARITY;
      STOP:
      if (rx_clk_cnt == SClkPeriod) rx_next = IDLE;
      else rx_next = STOP;
      default: rx_next = XXX;
    endcase
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      rx_data_cnt <= '0;
      rx_clk_cnt <= '0;
      data <= '0;
      write_req <= '0;
    end else begin
      rx_clk_cnt <= rx_clk_cnt + 1'b1;
      write_req <= '0;
      case (rx_state)
        IDLE: begin
          if (rx_sig == 1'b0) begin
            rx_clk_cnt <= '0;
          end
        end
        WAIT_START: begin
          // Sample in the middle of a period
          if (rx_clk_cnt == SClkPeriod + SClkPeriod / 2) begin
            rx_clk_cnt <= '0;
            data[rx_data_cnt[$clog2(DataBitsSize)-1:0]] <= rx_sig;
            rx_data_cnt <= rx_data_cnt + 1'b1;
          end
        end
        DATA: begin
          if (rx_clk_cnt == SClkPeriod) begin
            rx_clk_cnt <= '0;
            data[rx_data_cnt[$clog2(DataBitsSize)-1:0]] <= rx_sig;
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
            write_req <= '1;
            rx_data_cnt <= '0;
          end
        end
        default: ;
      endcase
    end
  end
endmodule
