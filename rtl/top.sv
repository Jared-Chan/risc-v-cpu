// Bring up
module top ();

  logic clk;
  logic rst_n;
  logic [31:0] idata;
  logic [31:0] iaddr;
  logic [31:0] data;
  logic [31:0] wdata;
  logic [31:0] addr;
  logic wr;

  cpu core (.*);
  dual_port_ram ram (.*);

  initial begin
    clk   = '0;
    rst_n = '1;
    #5;
    rst_n = '0;
    #5;
    rst_n = '1;

    forever begin
      #5;
      clk = ~clk;
    end

  end

  initial begin
    #20;
    repeat (1200) begin

      if (iaddr == 'h684) begin
        $display("time=%0t iaddr=0x%0h test failed!", $time, iaddr);
        $finish;
      end else if (iaddr == 'h698) begin
        $display("time=%0t iaddr=0x%0h test passed!", $time, iaddr);
        $finish;
      end
      #5;
    end
    $display("Finished.");
    $finish;
  end


endmodule
