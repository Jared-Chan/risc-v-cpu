/* read when empty: last read data
 * write when full: overwrite last written
 */
module uart_fifo #(
    parameter byte DataBitsSize = 8,
    parameter byte BufferSize   = 128  // must be power of 2
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
  logic next_empty, next_full;

  always_comb begin
    empty = write_idx == read_idx ? 1'b1 : 1'b0;
    full = (write_idx[IdxWidth] != read_idx[IdxWidth]) &
        (write_idx[IdxWidth-1:0] == read_idx[IdxWidth-1:0]) ? 1'b1 : 1'b0;
  end

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      read_idx  <= '0;
      write_idx <= '0;
    end else begin
      q <= buffer[read_idx];
      if (read_ack) begin
        if (!empty) begin
            q <= buffer[read_idx[IdxWidth-1:0] + 1'b1];
          read_idx <= read_idx + 1'b1;
        end else begin
            q <= buffer[read_idx[IdxWidth-1:0]];
          read_idx <= read_idx;
        end
      end
      if (write_req) begin
        buffer[write_idx[IdxWidth-1:0]] <= data;
        if (!full) write_idx <= write_idx + 1'b1;
        else write_idx <= write_idx;
      end
    end

  end

endmodule
