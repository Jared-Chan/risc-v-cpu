`include "config.svh"

module top (
    input logic clk,
    input logic rst_n,

    input  uart_rx,
    output uart_tx
);

  logic [31:0] idata;
  logic [31:0] iaddr;
  logic [31:0] wdata;
  logic [31:0] addr;
  logic wr, addr_strobe;

  wire [31:0] data;

  logic ram_select, io_select;

  address_decoder addr_dec (
      .clk(clk),
      .addr_i(addr),

      .ram_select_o(ram_select),
      .io_select_o (io_select)
  );

  cpu core (
      .clk(clk),
      .rst_n(rst_n),
      .iaddr_o(iaddr),
      .idata_i(idata),
      .addr_o(addr),
      .wdata_o(wdata),
      .data_i(data),
      .wr_o(wr),
      .data_addr_strobe_o(addr_strobe)
  );

  logic [31:0] ram_data_o;

  dual_port_ram ram (
      .clk(clk),
      .rst_n(rst_n),
      .iaddr(iaddr),
      .idata(idata),
      .addr(addr),
      .wdata(wdata),
      .data(ram_data_o),
      .wr(wr),
      .en(ram_select)
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
      .BaudRate(9600),
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
