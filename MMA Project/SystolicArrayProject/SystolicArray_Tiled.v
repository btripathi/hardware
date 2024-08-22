module SystolicArray_Tiled #(
    parameter SIZE = 16,  // Size of the systolic array (TILE_SIZE)
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH = 32,
    parameter ADDR_WIDTH = 16,  // Extended for large matrices
    parameter TILE_SIZE = 16,   // Size of the tile (same as SIZE here)
    parameter MATRIX_SIZE = 64  // Total matrix size (N x N)
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire enable_flash_attention,
    input wire write_enable,                     // Write enable for the configuration registers
    input wire [ADDR_WIDTH-1:0] write_addr,      // Write address for the configuration registers
    input wire [DATA_WIDTH-1:0] write_data,      // Write data for the configuration registers
    output reg done,
    output wire [ACC_WIDTH-1:0] result[TILE_SIZE*TILE_SIZE-1:0], // Partial result for this tile

    // DRAM interface
    output reg [ADDR_WIDTH-1:0] dram_addr_a,
    output reg [ADDR_WIDTH-1:0] dram_addr_b,
    input wire [DATA_WIDTH-1:0] dram_data_a,
    input wire [DATA_WIDTH-1:0] dram_data_b,

    // SRAM interface for tiles
    output wire [ADDR_WIDTH-1:0] sram_addr_a,
    output wire [DATA_WIDTH-1:0] sram_data_a,
    output wire sram_we_a,
    output wire [ADDR_WIDTH-1:0] sram_addr_b,
    output wire [DATA_WIDTH-1:0] sram_data_b,
    output wire sram_we_b
);

    // Programmable Registers
    wire [DATA_WIDTH-1:0] config_regs [0:7];

    ConfigurableRegisters #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REGISTERS(8)
    ) config_regs_inst (
        .clk(clk),
        .rst(rst),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data),
        .reg_out(config_regs)
    );

    // Internal Signals
    reg [ADDR_WIDTH-1:0] tile_x, tile_y;  // Coordinates of the current tile
    reg [ADDR_WIDTH-1:0] inner_k;         // Inner loop index for k (dimension of the summation)
    reg processing_tile;

    wire [ADDR_WIDTH-1:0] dma_src_addr_a = config_regs[0];
    wire [ADDR_WIDTH-1:0] dma_src_addr_b = config_regs[1];
    wire [ADDR_WIDTH-1:0] dma_dest_addr_a = config_regs[2];
    wire [ADDR_WIDTH-1:0] dma_dest_addr_b = config_regs[3];
    wire [ADDR_WIDTH-1:0] matrix_size = config_regs[4];
    wire [ADDR_WIDTH-1:0] tile_size = config_regs[5];

    wire [DATA_WIDTH-1:0] sram_a_out[TILE_SIZE*TILE_SIZE-1:0];
    wire [DATA_WIDTH-1:0] sram_b_out[TILE_SIZE*TILE_SIZE-1:0];
    reg [ACC_WIDTH-1:0] acc[TILE_SIZE*TILE_SIZE-1:0];  // Accumulation register for results
    // Signals to DMA controllers for loading tiles into SRAM
    reg start_dma_a, start_dma_b;
    wire dma_done_a, dma_done_b;

    // DMA Controllers for Matrix A and Matrix B tiles
    DMA_Controller_Tiled #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .TILE_SIZE(TILE_SIZE),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) dma_a (
        .clk(clk),
        .rst(rst),
        .start(start_dma_a),
        .src_addr(dma_src_addr_a),  // Source address configured via registers
        .dest_addr(dma_dest_addr_a),
        .tile_start_x(tile_x),
        .tile_start_y(inner_k),
        .done(dma_done_a),
        .dram_addr(dram_addr_a),
        .dram_data(dram_data_a),
        .sram_addr(sram_addr_a),
        .sram_data(sram_data_a),
        .sram_we(sram_we_a)
    );

    DMA_Controller_Tiled #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .TILE_SIZE(TILE_SIZE),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) dma_b (
        .clk(clk),
        .rst(rst),
        .start(start_dma_b),
        .src_addr(dma_src_addr_b),  // Source address configured via registers
        .dest_addr(dma_dest_addr_b),
        .tile_start_x(inner_k),
        .tile_start_y(tile_y),
        .done(dma_done_b),
        .dram_addr(dram_addr_b),
        .dram_data(dram_data_b),
        .sram_addr(sram_addr_b),
        .sram_data(sram_data_b),
        .sram_we(sram_we_b)
    );

    // Systolic Array Path
    wire [DATA_WIDTH-1:0] a_pipe[TILE_SIZE*TILE_SIZE-1:0];
    wire [DATA_WIDTH-1:0] b_pipe[TILE_SIZE*TILE_SIZE-1:0];
    wire [ACC_WIDTH-1:0] c_pipe[TILE_SIZE*TILE_SIZE-1:0];

    // FlashAttention module signals
    wire [DATA_WIDTH-1:0] attention_output[TILE_SIZE*TILE_SIZE-1:0];

    FlashAttention #(
        .SIZE(TILE_SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(TILE_SIZE * TILE_SIZE)
    ) flash_attention_inst (
        .clk(clk),
        .rst(rst),
        .query(sram_a_out),
        .key(sram_b_out),
        .value(c_pipe),
        .output_attention(attention_output)
    );

    genvar i, j;
    generate
        for (i = 0; i < SIZE; i = i + 1) begin: row_gen
            for (j = 0; i < SIZE; j = j + 1) begin: col_gen
                if (i == 0 && j == 0) begin
                    PE_BF16 #(.DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH)) pe (
                        .clk(clk),
                        .rst(rst),
                        .a_in(sram_a_out[i*SIZE + j]),
                        .b_in(sram_b_out[i*SIZE + j]),
                        .c_in(enable_flash_attention ? attention_output[i*SIZE + j] : acc[i*SIZE + j]),  // Use FlashAttention if enabled
                        .a_out(a_pipe[i*SIZE + j]),
                        .b_out(b_pipe[i*SIZE + j]),
                        .c_out(c_pipe[i*SIZE + j])
                    );
                end else if (i == 0) begin
                    PE_BF16 #(.DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH)) pe (
                        .clk(clk),
                        .rst(rst),
                        .a_in(a_pipe[i*SIZE + j - 1]),
                        .b_in(sram_b_out[i*SIZE + j]),
                        .c_in(c_pipe[i*SIZE + j - 1]),
                        .a_out(a_pipe[i*SIZE + j]),
                        .b_out(b_pipe[i*SIZE + j]),
                        .c_out(c_pipe[i*SIZE + j])
                    );
                end else if (j == 0) begin
                    PE_BF16 #(.DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH)) pe (
                        .clk(clk),
                        .rst(rst),
                        .a_in(sram_a_out[i*SIZE + j]),
                        .b_in(b_pipe[(i-1)*SIZE + j]),
                        .c_in(c_pipe[(i-1)*SIZE + j]),
                        .a_out(a_pipe[i*SIZE + j]),
                        .b_out(b_pipe[i*SIZE + j]),
                        .c_out(c_pipe[i*SIZE + j])
                    );
                end else begin
                    PE_BF16 #(.DATA_WIDTH(DATA_WIDTH), .ACC_WIDTH(ACC_WIDTH)) pe (
                        .clk(clk),
                        .rst(rst),
                        .a_in(a_pipe[i*SIZE + j - 1]),
                        .b_in(b_pipe[(i-1)*SIZE + j]),
                        .c_in(c_pipe[(i-1)*SIZE + j - 1]),
                        .a_out(a_pipe[i*SIZE + j]),
                        .b_out(b_pipe[i*SIZE + j]),
                        .c_out(c_pipe[i*SIZE + j])
                    );
                end
            end
        end
    endgenerate
    // State machine for controlling the tiling and processing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tile_x <= 0;
            tile_y <= 0;
            inner_k <= 0;
            processing_tile <= 0;
            done <= 0;
            start_dma_a <= 0;
            start_dma_b <= 0;
            // Initialize the accumulation registers
            for (i = 0; i < TILE_SIZE*TILE_SIZE; i = i + 1) begin
                acc[i] <= 0;
            end
        end else if (start) begin
            if (!processing_tile) begin
                // Start loading the next tile
                processing_tile <= 1;
                start_dma_a <= 1;
                start_dma_b <= 1;
            end else if (dma_done_a && dma_done_b) begin
                // DMA transfer completed, start processing the tile
                start_dma_a <= 0;
                start_dma_b <= 0;

                // Update accumulation
                for (i = 0; i < TILE_SIZE*TILE_SIZE; i = i + 1) begin
                    acc[i] <= acc[i] + c_pipe[i];  // Accumulate results from the current tile
                end

                // Check if all tiles are processed
                if (inner_k + TILE_SIZE >= matrix_size) begin
                    inner_k <= 0;
                    if (tile_x + TILE_SIZE >= matrix_size) begin
                        tile_x <= 0;
                        if (tile_y + TILE_SIZE >= matrix_size) begin
                            done <= 1;  // All tiles processed
                        end else begin
                            tile_y <= tile_y + TILE_SIZE;
                        end
                    end else begin
                        tile_x <= tile_x + TILE_SIZE;
                    end
                end else begin
                    inner_k <= inner_k + TILE_SIZE;
                end

                processing_tile <= 0;
            end
        end
    end

    // Output the final accumulated result
    generate
        for (i = 0; i < TILE_SIZE*TILE_SIZE; i = i + 1) begin
            assign result[i] = acc[i];
        end
    endgenerate

endmodule
