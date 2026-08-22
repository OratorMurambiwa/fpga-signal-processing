// 7-tap fixed-point FIR filter with ready/valid handshaking.

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

    logic signed [31:0] product0;
    logic signed [31:0] product1;
    logic signed [31:0] product2;
    logic signed [31:0] product3;
    logic signed [31:0] product4;
    logic signed [31:0] product5;
    logic signed [31:0] product6;

    logic signed [34:0] sum;

    integer i;


    // The FIR can take another sample when its output is free.
    assign input_ready =
        !output_valid || output_ready;


    // Calculate the next filtered sample.
    always_comb begin

        product0 = input_data    * 16'sd1638;
        product1 = delay_line[0] * 16'sd3277;
        product2 = delay_line[1] * 16'sd6554;
        product3 = delay_line[2] * 16'sd9830;
        product4 = delay_line[3] * 16'sd6554;
        product5 = delay_line[4] * 16'sd3277;
        product6 = delay_line[5] * 16'sd1638;

        sum =
            {{3{product0[31]}}, product0}
          + {{3{product1[31]}}, product1}
          + {{3{product2[31]}}, product2}
          + {{3{product3[31]}}, product3}
          + {{3{product4[31]}}, product4}
          + {{3{product5[31]}}, product5}
          + {{3{product6[31]}}, product6};

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

            // Only move forward when the next sample is accepted.
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

            // Clear the output after it has been accepted.
            else if (output_valid && output_ready) begin

                output_valid <= 1'b0;

            end

        end

    end

endmodule