// 7-tap fixed-point FIR filter with symmetric coefficients.

module FirFilter (
    input  logic               clk,
    input  logic               reset,
    input  logic               input_valid,
    output logic               input_ready,
    input  logic signed [15:0] input_data,
    output logic               output_valid,
    input  logic               output_ready,
    output logic signed [15:0] output_data
);

    logic signed [15:0] delay_line [0:5];

    // Pair samples that share the same coefficient.
    logic signed [16:0] pair0;
    logic signed [16:0] pair1;
    logic signed [16:0] pair2;

    logic signed [32:0] product0;
    logic signed [32:0] product1;
    logic signed [32:0] product2;
    logic signed [31:0] product3;

    logic signed [35:0] sum;

    integer i;

    assign input_ready = !output_valid || output_ready;

    always_comb begin
        // Symmetric 7-tap FIR:
        // c0*x0 + c1*x1 + c2*x2 + c3*x3
        //       + c2*x4 + c1*x5 + c0*x6
        pair0 =
            $signed({input_data[15], input_data})
            + $signed({delay_line[5][15], delay_line[5]});

        pair1 =
            $signed({delay_line[0][15], delay_line[0]})
            + $signed({delay_line[4][15], delay_line[4]});

        pair2 =
            $signed({delay_line[1][15], delay_line[1]})
            + $signed({delay_line[3][15], delay_line[3]});

        product0 = pair0 * 16'sd1638;
        product1 = pair1 * 16'sd3277;
        product2 = pair2 * 16'sd6554;
        product3 = delay_line[2] * 16'sd9830;

        sum =
            {{3{product0[32]}}, product0}
          + {{3{product1[32]}}, product1}
          + {{3{product2[32]}}, product2}
          + {{4{product3[31]}}, product3};
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            output_valid <= 1'b0;
            output_data <= 16'sd0;

            for (i = 0; i < 6; i = i + 1) begin
                delay_line[i] <= 16'sd0;
            end
        end
        else begin
            if (input_valid && input_ready) begin
                delay_line[5] <= delay_line[4];
                delay_line[4] <= delay_line[3];
                delay_line[3] <= delay_line[2];
                delay_line[2] <= delay_line[1];
                delay_line[1] <= delay_line[0];
                delay_line[0] <= input_data;

                output_data <= sum >>> 15;
                output_valid <= 1'b1;
            end
            else if (output_valid && output_ready) begin
                output_valid <= 1'b0;
            end
        end
    end

endmodule