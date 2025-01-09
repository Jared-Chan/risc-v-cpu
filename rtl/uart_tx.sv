module uart_tx #(
    parameter int BaudRate = 9600,
    parameter bit ParityBit = 0,
    parameter byte DataBitsSize = 8,
    parameter bit StopBitsSize = 1,
    parameter int ClockFreqHz = 10000000
) (
    input logic clk,
    input logic rst_n,
    input logic [DataBitsSize - 1:0] write_data,
    input logic write,
    output logic write_ready,
    output logic tx_sig
);
  typedef enum {
    IDLE = 0,
    WAIT_START = 1,
    DATA = 2,
    PARITY = 3,
    STOP = 4,
    XXX = 5
  } tx_state_e;

  tx_state_e tx_state, tx_next;

  localparam int SClkPeriod = ClockFreqHz / BaudRate;

  logic [7:0] tx_data_cnt;
  logic [31:0] tx_clk_cnt;  // need at least 1.5x SClkPeriod

  logic parity;
  assign parity = 0;  // No parity yet

  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n) tx_state <= IDLE;
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
      PARITY:
      if (tx_clk_cnt == SClkPeriod) tx_next = STOP;
      else tx_next = PARITY;
      STOP:
      // After SClkPeriod, it sets tx_sig to 1, after another, move to IDLE
      if (tx_clk_cnt == SClkPeriod * 2) tx_next = IDLE;
      else tx_next = STOP;
      default: tx_next = XXX;
    endcase
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      tx_data_cnt <= '0;
      tx_clk_cnt <= '0;
      tx_sig <= '1;
      write_ready <= '0;
    end else begin
      //$display("\x1B[31mUART TX \033[0m state is 0x%0h write is 0x%0h write_data is 0x%0h tx_data_cnt is 0x%0h tx_clk_cnt is 0x%8h tx_sig is 0x%1h SClkPeriod is 0x%0h DataBitsSize is 0x%0h",tx_state, write, write_data, tx_data_cnt, tx_clk_cnt, tx_sig, SClkPeriod, DataBitsSize);
      tx_clk_cnt  <= tx_clk_cnt + 1'b1;
      write_ready <= '0;
      case (tx_state)
        IDLE: begin
          if (write) begin
            tx_clk_cnt <= '0;
            tx_sig <= '0;
          end else begin
            write_ready <= '1;
          end
        end
        DATA: begin
          if (tx_clk_cnt == SClkPeriod) begin
            tx_sig <= write_data[tx_data_cnt[$clog2(DataBitsSize)-1:0]];
            tx_data_cnt <= tx_data_cnt + 1'b1;
            tx_clk_cnt <= '0;
      //$display("\x1B[32mUART TX \033[0m sent one bit");
          end
        end
        PARITY:
        if (tx_clk_cnt == SClkPeriod) begin
          tx_clk_cnt <= '0;
          tx_sig <= parity;
        end
        STOP: begin
          if (tx_clk_cnt == SClkPeriod) begin
            tx_data_cnt <= '0;
            tx_sig <= '1;
      //$display("\x1B[31mUART TX \033[0m transmit finished: write data: 0x%2h", write_data);
          end
        end
        default: ;
      endcase
    end
  end
endmodule

