// Bring up
module top (
);

    logic clk;
    logic rst_n;
    logic [31:0] idata;
    logic [31:0] iaddr;
    logic [31:0] data;
    logic [31:0] wdata;
    logic [31:0] addr;
    logic wr;

    cpu core (.*);

    initial begin
        clk = '0;
        rst_n = '0;
        #5;
        rst_n = '1;

        forever begin
            #5;
            clk = ~clk;
        end

    end

    initial begin
        #15;
        data = 32'h0000_0000;
        $display ("time=%0t iaddr=0x%0h wr=0x%0h", $time, iaddr, wr);
        #5;
        $display ("Finished.");
        $finish;
    end


endmodule
