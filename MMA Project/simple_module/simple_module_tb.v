module simple_module_tb;
    reg a;
    reg b;
    wire y;

    simple_module uut (
        .a(a),
        .b(b),
        .y(y)
    );

    initial begin
        $dumpfile("simple_module.vcd");
        $dumpvars(0, simple_module_tb);

        a = 0; b = 0;
        #10 a = 1; b = 0;
        #10 a = 0; b = 1;
        #10 a = 1; b = 1;
        #10 $finish;
    end
endmodule
