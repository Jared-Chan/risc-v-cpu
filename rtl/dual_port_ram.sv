module dual_port_ram (
    input logic clk,
    input logic rst_n,
    output logic [31:0] idata,
    input logic [31:0] iaddr,
    output logic [31:0] data,
    input logic [31:0] wdata,
    input logic [31:0] addr,
    input logic wr
);

  logic [7:0] mem[1024*4];  // 4kB

  // assume aligned
  // 'byte-addressable'
  assign data  = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
  assign idata = {mem[iaddr+3], mem[iaddr+2], mem[iaddr+1], mem[iaddr]};

  initial begin
    $readmemh("ram.mem", mem);
  end

  always_ff @(posedge clk) begin
    if (wr) begin
      mem[addr]   <= wdata[7:0];
      mem[addr+1] <= wdata[15:8];
      mem[addr+2] <= wdata[23:16];
      mem[addr+3] <= wdata[31:24];
    end
  end

endmodule
