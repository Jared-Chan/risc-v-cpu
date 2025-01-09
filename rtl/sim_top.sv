module sim_top (
    //input logic clk,
    //input logic rst_n
);

    logic clk, rst_n;

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

  initial begin
      clk = 0;
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
  /*
  initial begin
      #1000;
      $display("Finish sim top");
      $finish;
  end
  */
endmodule
