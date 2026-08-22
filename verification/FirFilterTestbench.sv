// Test the FIR filter, including backpressure behavior.

`timescale 1ns / 1ps

module FirFilterTestbench;

    logic clk;
    logic reset;

    logic signed [15:0] input_data;
    logic               input_valid;
    logic               input_ready;

    logic signed [15:0] output_data;
    logic               output_valid;
    logic               output_ready;

    logic signed [15:0] held_output;


    FirFilter dut (
        .clk(clk),
        .reset(reset),

        .input_valid(input_valid),
        .input_ready(input_ready),
        .input_data(input_data),

        .output_valid(output_valid),
        .output_ready(output_ready),
        .output_data(output_data)
    );


    // 100 MHz clock.
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end


    initial begin

        reset = 1'b1;

        input_data = 16'sd0;
        input_valid = 1'b0;

        output_ready = 1'b1;


        repeat (3) @(posedge clk);

        reset = 1'b0;


        // Send the first sample.
        send_sample(16'sd1000);


        // Wait until the FIR produces an output.
        wait (output_valid == 1'b1);

        @(negedge clk);

        $display(
            "FIR output before backpressure = %0d",
            output_data
        );


        // Stop accepting the FIR output.
        output_ready = 1'b0;

        held_output = output_data;


        // Keep the FIR stalled for 5 clock cycles.
        repeat (5) begin

            @(negedge clk);

            if (output_valid != 1'b1) begin
                $display(
                    "FAIL: output_valid dropped during backpressure."
                );
                $finish;
            end

            if (output_data != held_output) begin
                $display(
                    "FAIL: output_data changed during backpressure."
                );
                $finish;
            end

            if (input_ready != 1'b0) begin
                $display(
                    "FAIL: input_ready stayed high during backpressure."
                );
                $finish;
            end

        end


        $display(
            "PASS: FIR held its output during backpressure."
        );


        // Allow the output to move again.
        output_ready = 1'b1;

        @(negedge clk);


        // Send another sample after the stall.
        send_sample(16'sd2000);

        wait (output_valid == 1'b1);

        @(negedge clk);

        $display(
            "FIR output after backpressure = %0d",
            output_data
        );

        $display(
            "PASS: FIR resumed after backpressure."
        );


        $finish;

    end


    // Send one sample only when the FIR is ready.
    task send_sample(
        input logic signed [15:0] sample_value
    );
        begin

            @(negedge clk);

            input_data = sample_value;
            input_valid = 1'b1;

            while (!input_ready) begin
                @(negedge clk);
            end

            @(negedge clk);

            input_valid = 1'b0;

        end
    endtask

endmodule