`include "config.svh"

module dual_port_ram (
    input logic clk,
    input logic rst_n,
    output logic [31:0] idata,
    input logic [29:0] iaddr,
    output logic [31:0] data,
    input logic [31:0] wdata,
    input logic [29:0] addr,
    output logic [3:0] ibyte_en,
    output logic [3:0] byte_en,
    input logic wr
);

  logic [31:0] mem[256*`MEM_LEN_KB];

  initial begin
    $readmemh(`MEM_INIT_FILE, mem);
  end

  always_ff @(posedge clk) begin
      /*
      if (addr == 30'h3 && wr == 1'b1) begin
          $display("Writing to 0x03!");
      end
      if (wdata[7:0] == 8'h21 && wr == 1'b1) begin
          $display("Writing 0x21 to 0x%8h", addr);
      end
      if ( addr[29:26] == 4'hF && wr == 1'b1) begin
          $display("Writing 0x%8h to 0x%8h", wdata[7:0], addr);
      end
      */
    if (wr) begin
      if (byte_en[0]) mem[addr][7:0] <= wdata[7:0];
      if (byte_en[1]) mem[addr][15:8] <= wdata[15:8];
      if (byte_en[2]) mem[addr][23:16] <= wdata[23:16];
      if (byte_en[3]) mem[addr][31:24] <= wdata[31:24];
    end
    if (byte_en[0]) data[7:0] <= mem[addr][7:0];
    if (byte_en[1]) data[15:8] <= mem[addr][15:8];
    if (byte_en[2]) data[23:16] <= mem[addr][23:16];
    if (byte_en[3]) data[31:24] <= mem[addr][31:24];

    if (ibyte_en[0]) idata[7:0] <= mem[iaddr][7:0];
    if (ibyte_en[1]) idata[15:8] <= mem[iaddr][15:8];
    if (ibyte_en[2]) idata[23:16] <= mem[iaddr][23:16];
    if (ibyte_en[3]) idata[31:24] <= mem[iaddr][31:24];
  end

endmodule
