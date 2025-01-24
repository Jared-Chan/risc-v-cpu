`include "config.svh"

module top (
    input logic clk,
`ifdef ZMMUL
    input logic clk_mul,
`endif
    input logic rst_n,

    input  uart_rx,
    output uart_tx
);

  logic [31:0] idata;
  logic [29:0] iaddr;
  logic [31:0] wdata;
  logic [29:0] addr;
  logic wr, addr_strobe;
  logic [ 3:0] byte_en;
  logic [ 3:0] ibyte_en;

  wire  [31:0] data;

  logic ram_select, io_select;

  /*
  always_ff @(posedge clk) begin
      if ( addr[29:26] == 4'hF && wr == 1'b1) begin
          $display("ram sel %b io sel %b", ram_select, io_select);
      end
  end
  */

  address_decoder addr_dec (
      .clk(clk),
      .addr_i(addr),

      .ram_select_o(ram_select),
      .io_select_o (io_select)
  );

  cpu #(
      .ClockFreqHz(`CLK_FREQ)
  ) core (
      .clk(clk),
`ifdef ZMMUL
      .clk_mul(clk_mul),
`endif
      .rst_n(rst_n),
      .iaddr_o(iaddr),
      .idata_i(idata),
      .addr_o(addr),
      .wdata_o(wdata),
      .data_i(data),
      .wr_o(wr),
      .data_addr_strobe_o(addr_strobe),
      .byte_en_o(byte_en),
      .ibyte_en_o(ibyte_en)
  );

  logic [31:0] ram_data_o;
  logic ram_wr;
  assign ram_wr = ram_select ? wr : '0;

  dual_port_ram ram (
      .clk(clk),
      .rst_n(rst_n),
      .iaddr(iaddr),
      .idata(idata),
      .addr(addr),
      .wdata(wdata),
      .data(ram_data_o),
      .wr(ram_wr),
      .byte_en(byte_en),
      .ibyte_en(ibyte_en)
  );

  logic [3:0] uart_addr;
  logic [7:0] uart_wdata;
  logic [7:0] uart_data_o;
  logic [31:0] uart_data;
  logic uart_as;

  assign uart_addr = io_select ? addr[3:0] : '0;
  assign uart_wdata = io_select ? wdata[7:0] : '0;
  assign uart_as = io_select ? addr_strobe : '0;

  logic [31:0] data_mux;
  assign data_mux = ram_select ? ram_data_o : io_select ? {24'b0, uart_data_o} : 'Z;
  assign data = data_mux;

  uart #(
      .BaudRate(`UART_BAUD_RATE),
      .ParityBit(0),
      .DataBitsSize(8),
      .StopBitsSize(1),
      .BufferSize(128),
      .ClockFreqHz(`CLK_FREQ)
  ) uart_inst (
      .clk(clk),
      .rst_n(rst_n),
      .rx_sig(uart_rx),
      .tx_sig(uart_tx),

      .addr(uart_addr),
      .wdata(uart_wdata),
      .data(uart_data_o),
      .addr_strobe(uart_as)
  );

endmodule
