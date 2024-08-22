module SystolicArray_Tiled_tb;
    parameter SIZE = 4;  // Systolic array size
    parameter DATA_WIDTH = 16;
    parameter ACC_WIDTH = 32;
    parameter ADDR_WIDTH = 16;  // Extended for large matrices
    parameter TILE_SIZE = 4;
    parameter MATRIX_SIZE = 16; // Large matrix size

    reg clk;
    reg rst;
    reg start;
    reg enable_flash_attention;
    reg write_enable;
    reg [ADDR_WIDTH-1:0] write_addr;
    reg [DATA_WIDTH-1:0] write_data;
    wire done;
    wire [ACC_WIDTH-1:0] result[TILE_SIZE*TILE_SIZE-1:0];

    // Memory Arrays to Simulate DRAM and SRAM
    reg [DATA_WIDTH-1:0] dram [0:MATRIX_SIZE*MATRIX_SIZE-1];
    reg [DATA_WIDTH-1:0] sram_a [0:TILE_SIZE*TILE_SIZE-1];
    reg [DATA_WIDTH-1:0] sram_b [0:TILE_SIZE*TILE_SIZE-1];

    // Instantiate the SystolicArray_Tiled module
    SystolicArray_Tiled #(
        .SIZE(SIZE),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .TILE_SIZE(TILE_SIZE),
        .MATRIX_SIZE(MATRIX_SIZE)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .enable_flash_attention(enable_flash_attention),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data),
        .done(done),
        .result(result)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end

    // Initialize DRAM with some test data
    initial begin
        integer i;
        for (i = 0; i < MATRIX_SIZE*MATRIX_SIZE; i = i + 1) begin
            dram[i] = i;  // Simple pattern for testing
        end
    end

    // Simulation process
    initial begin
        rst = 1;
        start = 0;
        enable_flash_attention = 0;
        write_enable = 0;
        #10 rst = 0;

        // Configure registers
        #10 write_enable = 1;
        write_addr = 0; write_data = 16'h0000;  // DMA A source address
        #10 write_addr = 1; write_data = 16'h0100;  // DMA B source address
        #10 write_addr = 2; write_data = 16'h0200;  // DMA A destination address
        #10 write_addr = 3; write_data = 16'h0300;  // DMA B destination address
        #10 write_addr = 4; write_data = MATRIX_SIZE;  // Matrix size
        #10 write_addr = 5; write_data = TILE_SIZE;    // Tile size
        #10 write_enable = 0;

        // Start processing large matrices
        start = 1;
        #10 start = 0;

        wait(done);
        #100 $finish;
    end

    // Simulate DRAM reads (to connect with the DMA controllers)
    always @(posedge clk) begin
        if (uut.dma_a.dram_addr < MATRIX_SIZE*MATRIX_SIZE)
            sram_a[uut.dma_a.sram_addr] <= dram[uut.dma_a.dram_addr];
        
        if (uut.dma_b.dram_addr < MATRIX_SIZE*MATRIX_SIZE)
            sram_b[uut.dma_b.sram_addr] <= dram[uut.dma_b.dram_addr];
    end

    // Dump the result to a file for verification
    initial begin
        $dumpfile("SystolicArray_Tiled_tb.vcd");
        $dumpvars(0, SystolicArray_Tiled_tb);
    end
endmodule
