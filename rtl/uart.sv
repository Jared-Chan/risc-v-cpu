module uart #(
    parameter int BaudRate = 115200,
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
  // addr (addr_o of cpu) : bit [7:0]
  // 0x0 (0x00) : 7'b0, ready (read-only)
  // 0x1 (0x04) : next received data (read-only)
  // 0x2 (0x08) : 7'bX, write (write-only) (for repeated writes)
  // 0x3 (0x0C) : data to transmit (write-only)
  // 0x4 (0x10) : 7'b0, write ready (read-only)

  logic [DataBitsSize - 1:0] write_data;
  logic ready, write, write_ready;

  logic [DataBitsSize - 1:0] ufifo_data;
  logic [DataBitsSize - 1:0] ufifo_q;
  logic ufifo_full;
  logic ufifo_empty;
  logic ufifo_read_ack;
  logic ufifo_write_req;

  logic [31:0] timer = '0;
  always @(posedge clk, negedge rst_n)
    if (!rst_n) timer <= '0;
    else timer <= timer + 1;


  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      data <= '0;
      write <= '0;
      ufifo_read_ack <= 1'b0;
    end else if (addr_strobe) begin
      write <= '0;
      ufifo_read_ack <= 1'b0;
      case (addr)
        4'h0: begin
          if (ufifo_empty) data[0] <= 1'b0;
          else data[0] <= 1'b1;
        end
        4'h1: begin
          data <= ufifo_q;
          ufifo_read_ack <= 1'b1;
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
      ufifo_read_ack <= 1'b0;
    end
  end
  // end: data interface to cpu

  uart_fifo #(
      .DataBitsSize(DataBitsSize),
      .BufferSize  (BufferSize)
  ) ufifo (
      .clk(clk),
      .rst_n(rst_n),
      .read_ack(ufifo_read_ack),
      .write_req(ufifo_write_req),
      .data(ufifo_data),
      .q(ufifo_q),
      .full(ufifo_full),
      .empty(ufifo_empty)
  );

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
      .write_req(ufifo_write_req),
      .data(ufifo_data),
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
