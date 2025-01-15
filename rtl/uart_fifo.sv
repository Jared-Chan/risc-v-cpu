/* read when empty: last read data
 * write when full: overwrite last written
 */
module uart_fifo #(
    parameter byte DataBitsSize = 8,
    parameter byte  BufferSize   = 128  // must be power of 2
) (
    input logic clk,
    input logic rst_n,

    input logic read_ack,
    input logic write_req,
    input logic [DataBitsSize-1:0] data,

    output logic [DataBitsSize-1:0] q,
    output logic full,
    output logic empty
);

  localparam int IdxWidth = $clog2(BufferSize);

  logic [DataBitsSize - 1:0] buffer[BufferSize];
  logic [IdxWidth:0] write_idx, read_idx;
  logic [IdxWidth:0] next_write_idx, next_read_idx;
  logic next_empty, next_full;

  always_comb begin
    empty = write_idx == read_idx ? 1'b1 : 1'b0;
    full = (write_idx[IdxWidth] != read_idx[IdxWidth]) &
        (write_idx[IdxWidth-1:0] == read_idx[IdxWidth-1:0]) ? 1'b1 : 1'b0;

    if (!empty) next_read_idx = read_idx + 1'b1;
    else next_read_idx = read_idx;

    if (!full) next_write_idx = write_idx + 1'b1;
    else next_write_idx = write_idx;

  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      read_idx <= '0;
      write_idx <= '0;
    end else begin
      q <= buffer[read_idx];
      if (read_ack) begin
        read_idx <= next_read_idx;
        q <= buffer[next_read_idx[IdxWidth-1:0]];
      end
      if (write_req) begin
        write_idx <= next_write_idx;
        buffer[write_idx[IdxWidth-1:0]] <= data;
      end
    end

  end

endmodule
