module SystolicArray_tb;
    reg clk;
    reg rst;
    reg select_buf;        // Buffer selector
    reg we_a, we_b;        // Write enables for SRAM A and B
    reg [7:0] addr_a, addr_b; // Addresses for SRAM A and B
    reg [7:0] din_a, din_b;   // Data inputs for SRAM A and B
    wire [15:0] c[255:0];     // Output matrix C
    integer i, j;

    // Instantiate the SystolicArray
    SystolicArray uut (
        .clk(clk),
        .rst(rst),
        .select_buf(select_buf),
        .we_a(we_a),
        .we_b(we_b),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a),
        .din_b(din_b),
        .c(c)
    );

    // Initial block to load SRAM and run the simulation
    initial begin
        $dumpfile("SystolicArray.vcd");
        $dumpvars(0, SystolicArray_tb);

        clk = 0;
        rst = 1;
        select_buf = 0;
        we_a = 0;
        we_b = 0;
        #5 rst = 0;

        // Load matrix A into SRAM A, buffer 0
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                addr_a = i*16 + j;
                din_a = i + 1;    // Example pattern for matrix A
                we_a = 1;
                #10; // Wait for a clock cycle to write the data
            end
        end
        we_a = 0;  // Disable write enable for SRAM A

        // Load matrix B into SRAM B, buffer 0
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                addr_b = i*16 + j;
                din_b = j + 1;    // Example pattern for matrix B
                we_b = 1;
                #10; // Wait for a clock cycle to write the data
            end
        end
        we_b = 0;  // Disable write enable for SRAM B

        #10 select_buf = 1; // Switch to buffer 1 for reading
        #1000 $finish;  // Adjust the time to ensure the operation completes
    end

    // Generate clock signal
    always #5 clk = ~clk;
endmodule
