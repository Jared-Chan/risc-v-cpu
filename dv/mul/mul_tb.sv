module mul_tb;
  localparam byte Width = 32;
  logic rst_n;
  logic clk_sys;
  logic signed [Width-1:0] multiplicand;
  logic signed [Width-1:0] multiplier;
  logic start;
  logic multiplicand_signed;
  logic multiplier_signed;
  logic clk_mul;
  logic ready_sync;
  logic [Width-1:0] result_l;
  logic [Width-1:0] result_h;

  mul mul_inst (.*);

  logic signed [Width*2-1:0] expected;
  assign expected = multiplicand * multiplier;

  logic signed [Width*2-1:0] result_full;
  assign result_full = {result_h, result_l};

  initial begin
    rst_n = 1;
    #10;
    rst_n = 0;
    #10;
    rst_n = 1;
  end
  initial begin
    clk_sys = 0;
    #20;
    forever begin
      clk_sys = ~clk_sys;
      #10;
    end
  end
  initial begin
    clk_mul = 0;
    #20;
    forever begin
      clk_mul = ~clk_mul;
      #10;
    end
  end

  initial begin
    forever begin
      wait (ready_sync == 0);
      wait (ready_sync == 1);
      $display("At %t", $time);
      if (result_full == expected)
        $display("Expected. %d * %d = %d", multiplicand, multiplier, result_full);
      else begin
        $display("Error!    %d * %d = %d, expected %d", multiplicand, multiplier, result_full,
                 expected);
        $display("Error!    %h * %h = %h, expected %h", multiplicand, multiplier, result_full,
                 expected);
      end
    end
  end

  // Test cases
  initial begin
    multiplicand_signed = 1;
    multiplier_signed   = 1;
    #30;
    wait (ready_sync == 1);

    wait (clk_sys == 0);
    wait (clk_sys == 1);
    start = 1;
    multiplier = 1;
    multiplicand = 1;
    wait (clk_sys == 0);
    wait (clk_sys == 1);
    start = 0;
    wait (ready_sync == 0);
    wait (ready_sync == 1);

    wait (clk_sys == 0);
    wait (clk_sys == 1);
    start = 1;
    multiplier = 0;
    multiplicand = 0;
    wait (ready_sync == 0);
    start = 0;
    wait (ready_sync == 1);

    wait (clk_sys == 0);
    wait (clk_sys == 1);
    start = 1;
    multiplier = 1;
    multiplicand = 0;
    wait (ready_sync == 0);
    start = 0;
    wait (ready_sync == 1);

    wait (clk_sys == 0);
    wait (clk_sys == 1);
    start = 1;
    multiplier = 1000;
    multiplicand = 'hff;
    wait (ready_sync == 0);
    start = 0;
    wait (ready_sync == 1);

    wait (clk_sys == 0);
    wait (clk_sys == 1);
    start = 1;
    multiplier = -1000;
    multiplicand = 'hff;
    wait (ready_sync == 0);
    start = 0;
    wait (ready_sync == 1);

    wait (clk_sys == 0);
    wait (clk_sys == 1);
    start = 1;
    multiplier = -1000;
    multiplicand = -123;
    wait (ready_sync == 0);
    start = 0;
    wait (ready_sync == 1);

    wait (clk_sys == 0);
    wait (clk_sys == 1);
    start = 1;
    multiplier = 32'h0ABC1230;
    multiplicand = 32'h01234ABC;
    wait (ready_sync == 0);
    start = 0;
    wait (ready_sync == 1);

    wait (clk_sys == 0);
    wait (clk_sys == 1);
    start = 1;
    multiplier = 32'h8ABC1230;
    multiplicand = 32'h81234ABC;
    wait (ready_sync == 0);
    start = 0;
    wait (ready_sync == 1);

    wait (clk_sys == 0);
    wait (clk_sys == 1);
    start = 1;
    multiplier = 32'h8ABC1230;
    multiplicand = 32'h41234ABC;
    wait (ready_sync == 0);
    start = 0;
    wait (ready_sync == 1);

    wait (clk_sys == 0);
    wait (clk_sys == 1);
    start = 1;
    multiplier = 32'hFFFFFFFF;
    multiplicand = 32'hFFFFFFFF;
    wait (ready_sync == 0);
    start = 0;
    wait (ready_sync == 1);

    #10;
    $finish;
  end

endmodule
