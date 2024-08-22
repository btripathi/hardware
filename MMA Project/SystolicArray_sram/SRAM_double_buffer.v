module SRAM_double_buffer #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 256
)(
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] din,
    output reg [DATA_WIDTH-1:0] dout,
    input wire select_buf // Select buffer 0 or 1
);
    reg [DATA_WIDTH-1:0] mem0 [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] mem1 [0:DEPTH-1];

    always @(posedge clk) begin
        if (we) begin
            if (select_buf)
                mem1[addr] <= din;
            else
                mem0[addr] <= din;
        end else begin
            if (select_buf)
                dout <= mem1[addr];
            else
                dout <= mem0[addr];
        end
    end
endmodule
