// Test FirFilter using quantized signal samples from a text file.

`timescale 1ns / 1ps

module FirFilterTestbench;

    logic clk;
    logic reset;
    logic input_valid;
    logic signed [15:0] input_data;

    logic output_valid;
    logic signed [15:0] output_data;

    integer input_file;
    integer output_file;
    integer scan_result;
    integer sample;

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

    // Save every valid FIR output sample.
    always @(negedge clk) begin
        if (output_valid && output_file != 0) begin
            $fdisplay(
                output_file,
                "%0d",
                output_data
            );
        end
    end

    // Reset the filter and process input samples.
    initial begin
        reset = 1'b1;
        input_valid = 1'b0;
        input_data = 16'sd0;

        input_file = $fopen(
            "C:/Users/muram/fpga-signal-processing/simulation/data/signal_samples.txt",
            "r"
        );

        output_file = $fopen(
            "C:/Users/muram/fpga-signal-processing/simulation/data/rtl_filtered_samples.txt",
            "w"
        );

        if (input_file == 0) begin
            $display("Error: Could not open signal_samples.txt");
            $finish;
        end

        if (output_file == 0) begin
            $display("Error: Could not create rtl_filtered_samples.txt");
            $finish;
        end

        #20;

        reset = 1'b0;

        while (!$feof(input_file)) begin
            scan_result = $fscanf(
                input_file,
                "%d\n",
                sample
            );

            if (scan_result == 1) begin
                send_sample(sample);
            end
        end

        $fclose(input_file);

        // Wait long enough for the final FIR output to be written.
        repeat (10) begin
            @(posedge clk);
        end

        $fclose(output_file);

        $finish;
    end

    // Send one valid input sample to the FIR filter.
    task send_sample(
        input logic signed [15:0] sample_value
    );
        begin
            @(negedge clk);

            input_data = sample_value;
            input_valid = 1'b1;

            @(negedge clk);

            input_valid = 1'b0;
        end
    endtask

endmodule