module SystolicArray(
    input wire clk,
    input wire rst,
    input wire select_buf,          // Select buffer 0 or 1
    input wire we_a, we_b,          // Write enable for SRAM A and B
    input wire [7:0] addr_a, addr_b, // Address for SRAM A and B
    input wire [7:0] din_a, din_b,   // Data input for SRAM A and B
    output wire [15:0] c[255:0]      // Output matrix C
);
    wire [7:0] a[255:0];
    wire [7:0] b[255:0];
    wire [7:0] a_pipe[255:0];
    wire [7:0] b_pipe[255:0];
    wire [15:0] c_pipe[255:0];

    // Instantiate the SRAMs for matrices A and B
    SRAM_double_buffer #(.ADDR_WIDTH(8), .DATA_WIDTH(8), .DEPTH(256)) sram_a (
        .clk(clk),
        .we(we_a),
        .addr(addr_a),
        .din(din_a),
        .dout(a),
        .select_buf(select_buf)
    );

    SRAM_double_buffer #(.ADDR_WIDTH(8), .DATA_WIDTH(8), .DEPTH(256)) sram_b (
        .clk(clk),
        .we(we_b),
        .addr(addr_b),
        .din(din_b),
        .dout(b),
        .select_buf(select_buf)
    );

    genvar i, j;
    generate
        for (i = 0; i < 16; i = i + 1) begin: row_gen
            for (j = 0; j < 16; j = j + 1) begin: col_gen
                if (i == 0 && j == 0) begin
                    PE pe(.clk(clk), .rst(rst), .a_in(a[i*16 + j]), .b_in(b[i*16 + j]), .c_in(0), .a_out(a_pipe[i*16 + j]), .b_out(b_pipe[i*16 + j]), .c_out(c_pipe[i*16 + j]));
                end else if (i == 0) begin
                    PE pe(.clk(clk), .rst(rst), .a_in(a_pipe[i*16 + j - 1]), .b_in(b[i*16 + j]), .c_in(c_pipe[i*16 + j - 1]), .a_out(a_pipe[i*16 + j]), .b_out(b_pipe[i*16 + j]), .c_out(c_pipe[i*16 + j]));
                end else if (j == 0) begin
                    PE pe(.clk(clk), .rst(rst), .a_in(a[i*16 + j]), .b_in(b_pipe[(i-1)*16 + j]), .c_in(c_pipe[(i-1)*16 + j]), .a_out(a_pipe[i*16 + j]), .b_out(b_pipe[i*16 + j]), .c_out(c_pipe[i*16 + j]));
                end else begin
                    PE pe(.clk(clk), .rst(rst), .a_in(a_pipe[i*16 + j - 1]), .b_in(b_pipe[(i-1)*16 + j]), .c_in(c_pipe[i*16 + j - 1]), .a_out(a_pipe[i*16 + j]), .b_out(b_pipe[i*16 + j]), .c_out(c_pipe[i*16 + j]));
                end
            end
        end
    endgenerate

    assign c = c_pipe;
endmodule
