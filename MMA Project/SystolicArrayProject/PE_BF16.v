module PE_BF16 #(
    parameter DATA_WIDTH = 16,  // BF16 is 16 bits
    parameter ACC_WIDTH = 32    // Accumulation width for results
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] a_in,  // BF16 input a
    input wire [DATA_WIDTH-1:0] b_in,  // BF16 input b
    input wire [ACC_WIDTH-1:0] c_in,   // Accumulator input
    output reg [DATA_WIDTH-1:0] a_out, // BF16 output a
    output reg [DATA_WIDTH-1:0] b_out, // BF16 output b
    output reg [ACC_WIDTH-1:0] c_out   // Accumulated output
);

    // Extract sign, exponent, and mantissa from BF16 inputs
    wire sign_a = a_in[15];
    wire [7:0] exp_a = a_in[14:7];
    wire [6:0] mant_a = a_in[6:0];

    wire sign_b = b_in[15];
    wire [7:0] exp_b = b_in[14:7];
    wire [6:0] mant_b = b_in[6:0];

    // Perform BF16 multiplication
    wire sign_mult = sign_a ^ sign_b;
    wire [15:0] mant_mult = {1'b1, mant_a} * {1'b1, mant_b}; // Include the implicit leading 1
    wire [7:0] exp_mult = exp_a + exp_b - 8'd127;

    // Normalize the result if necessary
    wire [7:0] final_exp = mant_mult[15] ? exp_mult + 1'b1 : exp_mult;
    wire [6:0] final_mant = mant_mult[15] ? mant_mult[14:8] : mant_mult[13:7];

    wire [DATA_WIDTH-1:0] mult_result = {sign_mult, final_exp, final_mant};

    // Accumulation
    wire [ACC_WIDTH-1:0] extended_mult_result = {16'b0, mult_result}; // Extend to accumulator width
    wire [ACC_WIDTH-1:0] add_result = c_in + extended_mult_result;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_out <= 0;
        end else begin
            c_out <= add_result;
            a_out <= a_in;
            b_out <= b_in;
        end
    end
endmodule

