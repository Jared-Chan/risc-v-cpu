module address_decoder (
    input logic clk,
    input logic [29:0] addr_i,

    output logic ram_select_o,
    output logic io_select_o
);

  always_comb begin

    io_select_o  = '0;
    ram_select_o = '0;

    // ram: 'h0000_0000 to 'h0FFF_FFFF
    if (addr_i[29:26] == 4'h0) begin
      ram_select_o = '1;
    end

    // io: 'hF000_0000 to 'hF000_FFFF
    if (addr_i[29:14] == 16'hF000) begin
      io_select_o = '1;
    end
  end

endmodule

