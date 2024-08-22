module PE(
    input wire clk,
    input wire rst,
    input wire [7:0] a_in,
    input wire [7:0] b_in,
    input wire [15:0] c_in,
    output reg [7:0] a_out,
    output reg [7:0] b_out,
    output reg [15:0] c_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_out <= 0;
        end else begin
            c_out <= c_in + a_in * b_in;
            a_out <= a_in;
            b_out <= b_in;
        end
    end
endmodule
