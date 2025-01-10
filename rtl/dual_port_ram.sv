`include "config.svh"

module dual_port_ram (
    input logic clk,
    input logic rst_n,
    output logic [31:0] idata,
    input logic [31:0] iaddr,
    output logic [31:0] data,
    input logic [31:0] wdata,
    input logic [31:0] addr,
    input logic wr,
    input logic en
);

  logic [7:0] mem[1024*`MEM_LEN_KB];

  initial begin
    $readmemh(`MEM_INIT_FILE, mem);
  end

  always_ff @(posedge clk) begin
    if (en) begin
      if (wr) begin
        mem[addr]   <= wdata[7:0];
        mem[addr+1] <= wdata[15:8];
        mem[addr+2] <= wdata[23:16];
        mem[addr+3] <= wdata[31:24];
      end
      // assume aligned
      // 'byte-addressable'
      data <= {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
    end
    idata <= {mem[iaddr+3], mem[iaddr+2], mem[iaddr+1], mem[iaddr]};
  end

endmodule
