// Test the PeakDetector module with known magnitudes.

`timescale 1ns / 1ps

module PeakDetectorTestbench;

    logic clk;
    logic reset;
    logic input_valid;
    logic frame_start;
    logic frame_end;

    logic [32:0] magnitude_in;
    logic [9:0] bin_index;

    logic peak_valid;
    logic [9:0] peak_bin;
    logic [32:0] peak_magnitude;

    PeakDetector dut (
        .clk(clk),
        .reset(reset),
        .input_valid(input_valid),
        .frame_start(frame_start),
        .frame_end(frame_end),
        .magnitude_in(magnitude_in),
        .bin_index(bin_index),
        .peak_valid(peak_valid),
        .peak_bin(peak_bin),
        .peak_magnitude(peak_magnitude)
    );

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        reset = 1'b1;
        input_valid = 1'b0;
        frame_start = 1'b0;
        frame_end = 1'b0;
        magnitude_in = 33'd0;
        bin_index = 10'd0;

        #20;

        reset = 1'b0;

        send_bin(10'd0, 33'd100, 1'b1, 1'b0);
        send_bin(10'd1, 33'd500, 1'b0, 1'b0);
        send_bin(10'd2, 33'd200, 1'b0, 1'b0);
        send_bin(10'd3, 33'd900, 1'b0, 1'b0);
        send_bin(10'd4, 33'd300, 1'b0, 1'b1);

        @(posedge clk);

        if (
            peak_valid
            && peak_bin == 10'd3
            && peak_magnitude == 33'd900
        ) begin
            $display("PASS");
        end
        else begin
            $display(
                "FAIL: peak_bin=%0d, peak_magnitude=%0d",
                peak_bin,
                peak_magnitude
            );
        end

        $finish;
    end

    task send_bin(
        input logic [9:0] bin_value,
        input logic [32:0] magnitude_value,
        input logic start_value,
        input logic end_value
    );
        begin
            @(negedge clk);

            bin_index = bin_value;
            magnitude_in = magnitude_value;
            input_valid = 1'b1;
            frame_start = start_value;
            frame_end = end_value;

            @(negedge clk);

            input_valid = 1'b0;
            frame_start = 1'b0;
            frame_end = 1'b0;
        end
    endtask

endmodule