module FlashAttention #(
    parameter SIZE = 16,
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH = 32,
    parameter ADDR_WIDTH = 8,
    parameter DEPTH = SIZE * SIZE
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] query[DEPTH-1:0],   // Input query matrix
    input wire [DATA_WIDTH-1:0] key[DEPTH-1:0],     // Input key matrix
    input wire [DATA_WIDTH-1:0] value[DEPTH-1:0],   // Input value matrix
    output wire [DATA_WIDTH-1:0] output_attention[DEPTH-1:0] // Output attention matrix
);

    wire [ACC_WIDTH-1:0] qk_product[DEPTH-1:0];
    wire [DATA_WIDTH-1:0] qk_softmax[DEPTH-1:0];
    wire [ACC_WIDTH-1:0] qk_scaled[DEPTH-1:0];
    wire [ACC_WIDTH-1:0] attention[DEPTH-1:0];

    genvar i, j;
    generate
        for (i = 0; i < SIZE; i = i + 1) begin: row_gen
            for (j = 0; j < SIZE; j = j + 1) begin: col_gen

                // Compute Query-Key Product
                assign qk_product[i*SIZE + j] = query[i*SIZE + j] * key[j*SIZE + i];

                // Scale the QK product by a factor (e.g., 1/sqrt(d_k))
                assign qk_scaled[i*SIZE + j] = qk_product[i*SIZE + j] >> 2;  // Example scaling

                // Apply Softmax (for simplicity, assume identity)
                assign qk_softmax[i*SIZE + j] = qk_scaled[i*SIZE + j][DATA_WIDTH-1:0];

                // Multiply the softmax output with the value matrix
                assign attention[i*SIZE + j] = qk_softmax[i*SIZE + j] * value[i*SIZE + j];

                // Store the result
                assign output_attention[i*SIZE + j] = attention[i*SIZE + j][DATA_WIDTH-1:0]; // Truncate to BF16
            end
        end
    endgenerate
endmodule
