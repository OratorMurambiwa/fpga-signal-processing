// Test the FirFilter module with a short sequence of input samples.

`timescale 1ns / 1ps

module FirFilterTestbench;

    logic clk;
    logic reset;
    logic input_valid;
    logic signed [15:0] input_data;

    logic output_valid;
    logic signed [15:0] output_data;

    // Instantiate the FIR filter being tested.
    FirFilter dut (
        .clk(clk),
        .reset(reset),
        .input_valid(input_valid),
        .input_data(input_data),
        .output_valid(output_valid),
        .output_data(output_data)
    );

    // Generate a 100 MHz clock.
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    // Apply reset and send test samples.
    initial begin
        reset = 1'b1;
        input_valid = 1'b0;
        input_data = 16'sd0;

        #20;

        reset = 1'b0;

        send_sample(16'sd1000);
        send_sample(16'sd2000);
        send_sample(16'sd3000);
        send_sample(16'sd4000);
        send_sample(16'sd5000);
        send_sample(16'sd6000);
        send_sample(16'sd7000);
        send_sample(16'sd8000);

        #50;

        $finish;
    end

    // Send one valid input sample to the FIR filter.
    task send_sample(input logic signed [15:0] sample);
        begin
            @(negedge clk);

            input_data = sample;
            input_valid = 1'b1;

            @(negedge clk);

            input_valid = 1'b0;
        end
    endtask

endmodule