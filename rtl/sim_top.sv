`include "config.svh"

module sim_top (
    //input logic clk,
    //input logic rst_n
);

  logic clk, rst_n;
`ifdef ZMMUL
  logic clk_mul;
`endif


  logic uart_rx, uart_tx;
  top soc (
      .clk(clk),
`ifdef ZMMUL
      .clk_mul(clk_mul),
`endif
      .rst_n(rst_n),
      .uart_rx(uart_rx),
      .uart_tx(uart_tx)
  );

  mock_uart_tx #(
      .BaudRate(`UART_BAUD_RATE),
      .ParityBit(0),
      .DataBitsSize(8),
      .StopBitsSize(1),
      .ClockFreqHz(`CLK_FREQ)
  ) mock_tx (
      .clk(clk),
      .rst_n(rst_n),
      .tx_sig(uart_rx)
  );

  mock_uart_rx #(
      .BaudRate(`UART_BAUD_RATE),
      .ParityBit(0),
      .DataBitsSize(8),
      .StopBitsSize(1),
      .BufferSize(128),
      .ClockFreqHz(`CLK_FREQ)
  ) mock_rx (
      .clk(clk),
      .rst_n(rst_n),
      .rx_sig(uart_tx)
  );

  initial begin
    clk   = 0;
    rst_n = 1;
    #5;
    rst_n = 0;
    #5;
    rst_n = 1;
    #5;
    forever begin
      clk = ~clk;
      #5;
    end
  end

`ifdef ZMMUL
  initial begin
    clk_mul = 0;
    forever begin
      clk_mul = ~clk_mul;
      #1;
    end
  end
`endif
  /*
  initial begin
      #1000;
      $display("Finish sim top");
      $finish;
  end
  */
endmodule
