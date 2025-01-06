module sim_top (
    input logic clk,
    input logic rst_n
);

  logic uart_rx, uart_tx;
  top soc (
      .clk(clk),
      .rst_n(rst_n),
      .uart_rx(uart_rx),
      .uart_tx(uart_tx)
  );

  assign uart_rx = '0;

  mock_uart_rx mock_rx (
      .clk(clk),
      .rst_n(rst_n),
      .rx_sig(uart_tx)
  );
endmodule
