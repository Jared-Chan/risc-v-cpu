module uart #(
    parameter int BaudRate = 9600,
    parameter bit ParityBit = 0,
    parameter byte DataBitsSize = 8,
    parameter int StopBitsSize = 1,
    parameter byte BufferSize = 64,
    parameter int ClockFreqHz = 10000000
) (
    input  logic clk,
    input  logic rst_n,
    input  logic rx_sig,
    output logic tx_sig,

    input logic [3:0] addr,
    input logic [7:0] wdata,
    output logic [7:0] data,
    input logic addr_strobe
);

  // begin: data interface to cpu
  // addr : bit [7:0]
  // 0x0 : 7'b0, ready (read-only)
  // 0x1 : next received data (read-only)
  // 0x2 : 7'bX, write (write-only)
  // 0x3 : data to transmit (write-only)
  // 0x4 : 7'b0, write ready (read-only)

  logic [DataBitsSize - 1:0] read_buffer[BufferSize];
  logic [DataBitsSize - 1:0] write_data;
  logic [$clog2(BufferSize)-1:0] next_rx_data_idx, cur_read_data_idx;
  logic ready, write, write_ready;

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      data <= '0;
      cur_read_data_idx <= '0;
      write <= '0;
    end else if (addr_strobe) begin
      write <= '0;
      case (addr)
        4'h0: begin
          data[0] <= ready;
        end
        4'h1: begin
          data <= read_buffer[cur_read_data_idx];
          if (cur_read_data_idx != next_rx_data_idx) begin
            cur_read_data_idx <= cur_read_data_idx + 1;
          end
        end
        4'h2: begin
          write <= wdata[0];
        end
        4'h3: begin
          write_data <= wdata;
          write <= '1;
        end
        4'h4: begin
          data[0] <= write_ready;
        end
        default: begin
        end
      endcase
      //$display("\x1B[32mUART CTRL \033[0m addr is 0x%0h ready is 0x%0h data is 0x%0h write is 0x%0h write_data is 0x%0h write_ready is 0x%0h",addr, ready, read_buffer[cur_read_data_idx], wdata[0], wdata, write_ready);
    end else begin
      write <= '0;
    end
  end
  // end: data interface to cpu

  uart_rx #(
      .BaudRate(BaudRate),
      .ParityBit(ParityBit),
      .DataBitsSize(DataBitsSize),
      .StopBitsSize(StopBitsSize),
      .BufferSize(BufferSize),
      .ClockFreqHz(ClockFreqHz)
  ) rx (
      .clk(clk),
      .rst_n(rst_n),
      .next_rx_data_idx(next_rx_data_idx),
      .ready(ready),
      .read_buffer(read_buffer),
      .rx_sig(rx_sig)
  );

  uart_tx #(
      .BaudRate(BaudRate),
      .ParityBit(ParityBit),
      .DataBitsSize(DataBitsSize),
      .StopBitsSize(StopBitsSize),
      .ClockFreqHz(ClockFreqHz)
  ) tx (
      .clk(clk),
      .rst_n(rst_n),
      .write_data(write_data),
      .write(write),
      .write_ready(write_ready),
      .tx_sig(tx_sig)
  );
endmodule
