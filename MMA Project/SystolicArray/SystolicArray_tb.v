module SystolicArray_tb;
    reg clk;
    reg rst;
    reg [7:0] a[255:0];  // Flattened array (16x16 = 256 elements)
    reg [7:0] b[255:0];  // Flattened array (16x16 = 256 elements)
    wire [15:0] c[255:0]; // Flattened array (16x16 = 256 elements)

    SystolicArray uut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .c(c)
    );

    integer i, j;

    initial begin
	$dumpfile("SystolicArray.vcd");
        $dumpvars(0, SystolicArray_tb);
        clk = 0;
        rst = 1;
        #5 rst = 0;

        // Initialize matrices A and B
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                a[i*16 + j] = i + 1; // or any pattern you'd like to test
                b[i*16 + j] = j + 1; // or any pattern you'd like to test
            end
        end

        #1000000 $finish;  // Adjust the time to ensure the operation completes
    end

    always #5 clk = ~clk;
endmodule	
