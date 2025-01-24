`include "config.svh"

module top (
    input CLOCK_50,
    input KEY_N_0,

    input  GPIO_1_34,
    output GPIO_1_35,

    output logic [9:0] LEDR
);
  logic rst_n;
  logic uart_rx;
  logic uart_tx;

  assign rst_n = KEY_N_0;
  assign uart_rx = GPIO_1_34;
  assign GPIO_1_35 = uart_tx;

  wire pll_outclk;
  wire pll_outclk_ram;
  wire pll_outclk_mul;
  pll pll_inst (
      .refclk(CLOCK_50),
      .rst(~rst_n),
      .outclk_0(pll_outclk),
      .outclk_1(pll_outclk_ram),
      .outclk_2(pll_outclk_mul)
  );

  logic [31:0] clk_cnt = 0;
  always_ff @(posedge pll_outclk) begin
    clk_cnt <= clk_cnt + 1;
    if (clk_cnt[20] == 0) LEDR[0] <= ~LEDR[0];
  end


  logic [31:0] idata;
  logic [29:0] iaddr;
  logic [31:0] wdata;
  logic [29:0] addr;
  logic wr, addr_strobe;
  logic [ 3:0] byte_en;
  logic [ 3:0] ibyte_en;

  wire  [31:0] data;

  logic ram_select, io_select;

  address_decoder addr_dec (
      .clk(pll_outclk),
      .addr_i(addr),

      .ram_select_o(ram_select),
      .io_select_o (io_select)
  );

  cpu #(
      .ClockFreqHz(`CLK_FREQ)
  ) core (
      .clk(pll_outclk),
`ifdef ZMMUL
      .clk_mul(pll_outclk_mul),
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

  dual_port_ram dual_port_ram_inst (
      .address_a(iaddr),
      .address_b(addr),
      .byteena_a(ibyte_en),
      .byteena_b(byte_en),
      .clock(pll_outclk_ram),
      .enable(1'b1),
      .data_a(32'b0),
      .data_b(wdata),
      .wren_a(1'b0),
      .wren_b(ram_wr),
      .q_a(idata),
      .q_b(ram_data_o)
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
      .BufferSize(8),
      .ClockFreqHz(`CLK_FREQ)
  ) uart_inst (
      .clk(pll_outclk),
      .rst_n(rst_n),
      .rx_sig(uart_rx),
      .tx_sig(uart_tx),

      .addr(uart_addr),
      .wdata(uart_wdata),
      .data(uart_data_o),
      .addr_strobe(uart_as)
  );


endmodule
