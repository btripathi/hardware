module DMA_Controller_Tiled #(
    parameter ADDR_WIDTH = 16,  // Address width for larger matrices
    parameter DATA_WIDTH = 16,  // Data width (e.g., BF16 is 16 bits)
    parameter TILE_SIZE = 16,   // Size of each tile (T x T)
    parameter MATRIX_SIZE = 64  // Total matrix size (N x N)
)(
    input wire clk,
    input wire rst,
    input wire start,                      // Start the DMA transfer
    input wire [ADDR_WIDTH-1:0] src_addr,  // Base source address in DRAM
    input wire [ADDR_WIDTH-1:0] dest_addr, // Base destination address in SRAM
    input wire [ADDR_WIDTH-1:0] tile_start_x, tile_start_y, // Start coordinates of the tile in the matrix
    output reg done,                       // DMA transfer completion signal
    output reg [ADDR_WIDTH-1:0] dram_addr, // Address for reading from DRAM
    input wire [DATA_WIDTH-1:0] dram_data, // Data read from DRAM
    output reg [ADDR_WIDTH-1:0] sram_addr, // Address for writing to SRAM
    output reg [DATA_WIDTH-1:0] sram_data, // Data to write into SRAM
    output reg sram_we                     // SRAM write enable signal
);

    reg [ADDR_WIDTH-1:0] count_x, count_y;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 0;
            count_x <= 0;
            count_y <= 0;
            dram_addr <= 0;
            sram_addr <= 0;
            sram_we <= 0;
        end else if (start) begin
            if (count_y < TILE_SIZE) begin
                if (count_x < TILE_SIZE) begin
                    // Calculate the DRAM address for the current tile element
                    dram_addr <= src_addr + (tile_start_y + count_y) * MATRIX_SIZE + (tile_start_x + count_x);
                    // Calculate the SRAM address for the corresponding tile element
                    sram_addr <= dest_addr + count_y * TILE_SIZE + count_x;
                    sram_data <= dram_data;
                    sram_we <= 1;  // Enable SRAM write
                    count_x <= count_x + 1;
                end else begin
                    count_x <= 0;
                    count_y <= count_y + 1;
                end
            end else begin
                sram_we <= 0;  // Disable SRAM write
                done <= 1;     // Signal that the DMA transfer is done
            end
        end else begin
            sram_we <= 0;  // Ensure SRAM write is disabled when not in use
        end
    end
endmodule
