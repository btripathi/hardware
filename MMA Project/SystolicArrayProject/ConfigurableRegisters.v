module ConfigurableRegisters #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 16,
    parameter NUM_REGISTERS = 8  // Number of programmable registers
)(
    input wire clk,
    input wire rst,
    input wire write_enable,
    input wire [ADDR_WIDTH-1:0] write_addr, // Address to select which register to write to
    input wire [DATA_WIDTH-1:0] write_data, // Data to be written to the selected register
    output wire [DATA_WIDTH-1:0] reg_out [0:NUM_REGISTERS-1] // Output the values of all registers
);

    reg [DATA_WIDTH-1:0] registers [0:NUM_REGISTERS-1];

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < NUM_REGISTERS; i = i + 1) begin
                registers[i] <= 0;
            end
        end else if (write_enable) begin
            registers[write_addr] <= write_data;
        end
    end

    generate
        for (i = 0; i < NUM_REGISTERS; i = i + 1) begin : assign_outputs
            assign reg_out[i] = registers[i];
        end
    endgenerate

endmodule
