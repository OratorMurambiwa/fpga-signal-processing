// Implement a 7-tap FIR low-pass filter using signed fixed-point arithmetic.

module FirFilter (
    input  logic                    clk,
    input  logic                    reset,
    input  logic                    input_valid,
    input  logic signed [15:0]      input_data,

    output logic                    output_valid,
    output logic signed [15:0]      output_data
);

    // FIR coefficients stored in Q1.15 fixed-point format.
    localparam logic signed [15:0] COEFF_0 = 16'sd1638;
    localparam logic signed [15:0] COEFF_1 = 16'sd3277;
    localparam logic signed [15:0] COEFF_2 = 16'sd6554;
    localparam logic signed [15:0] COEFF_3 = 16'sd9830;
    localparam logic signed [15:0] COEFF_4 = 16'sd6554;
    localparam logic signed [15:0] COEFF_5 = 16'sd3277;
    localparam logic signed [15:0] COEFF_6 = 16'sd1638;

    // Store the previous six input samples.
    logic signed [15:0] delay_line [0:5];

    // Store the result of each sample-coefficient multiplication.
    logic signed [31:0] product_0;
    logic signed [31:0] product_1;
    logic signed [31:0] product_2;
    logic signed [31:0] product_3;
    logic signed [31:0] product_4;
    logic signed [31:0] product_5;
    logic signed [31:0] product_6;

    // Use a wider value so the products can be added safely.
    logic signed [34:0] sum;

    integer index;

    // Multiply each signal sample by its FIR coefficient.
    always_comb begin
        product_0 = input_data    * COEFF_0;
        product_1 = delay_line[0] * COEFF_1;
        product_2 = delay_line[1] * COEFF_2;
        product_3 = delay_line[2] * COEFF_3;
        product_4 = delay_line[3] * COEFF_4;
        product_5 = delay_line[4] * COEFF_5;
        product_6 = delay_line[5] * COEFF_6;

        sum = product_0
            + product_1
            + product_2
            + product_3
            + product_4
            + product_5
            + product_6;
    end

    // Shift samples through the delay line and produce the filtered output.
    always_ff @(posedge clk) begin
        if (reset) begin
            output_data  <= 16'sd0;
            output_valid <= 1'b0;

            for (index = 0; index < 6; index = index + 1) begin
                delay_line[index] <= 16'sd0;
            end
        end
        else begin
            output_valid <= 1'b0;

            if (input_valid) begin
                delay_line[5] <= delay_line[4];
                delay_line[4] <= delay_line[3];
                delay_line[3] <= delay_line[2];
                delay_line[2] <= delay_line[1];
                delay_line[1] <= delay_line[0];
                delay_line[0] <= input_data;

                output_data <= sum >>> 15;
                output_valid <= 1'b1;
            end
        end
    end

endmodule