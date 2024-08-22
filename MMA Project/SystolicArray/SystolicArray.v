module SystolicArray(
    input wire clk,
    input wire rst,
    input wire [7:0] a[255:0],  // Flattened array (16x16 = 256 elements)
    input wire [7:0] b[255:0],  // Flattened array (16x16 = 256 elements)
    output wire [15:0] c[255:0] // Flattened array (16x16 = 256 elements)
);
    wire [7:0] a_pipe[255:0];
    wire [7:0] b_pipe[255:0];
    wire [15:0] c_pipe[255:0];

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
