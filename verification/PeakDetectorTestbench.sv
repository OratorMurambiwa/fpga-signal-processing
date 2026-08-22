// Test the peak detector across multiple frames.

`timescale 1ns / 1ps

module PeakDetectorTestbench;

    logic clk;
    logic reset;

    logic        input_valid;
    logic [32:0] magnitude_in;
    logic [9:0]  bin_index;

    logic frame_start;
    logic frame_end;

    logic        peak_valid;
    logic [9:0]  peak_bin;
    logic [32:0] peak_magnitude;


    PeakDetector dut (
        .clk(clk),
        .reset(reset),

        .input_valid(input_valid),
        .magnitude_in(magnitude_in),
        .bin_index(bin_index),

        .frame_start(frame_start),
        .frame_end(frame_end),

        .peak_valid(peak_valid),
        .peak_bin(peak_bin),
        .peak_magnitude(peak_magnitude)
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

        input_valid = 1'b0;
        magnitude_in = 33'd0;
        bin_index = 10'd0;

        frame_start = 1'b0;
        frame_end = 1'b0;


        repeat (3) @(posedge clk);

        reset = 1'b0;


        // First frame:
        // 100, 500, 200, 900, 300
        // Expected peak = 900 at bin 3.

        send_sample(33'd100, 10'd0, 1'b1, 1'b0);
        send_sample(33'd500, 10'd1, 1'b0, 1'b0);
        send_sample(33'd200, 10'd2, 1'b0, 1'b0);
        send_sample(33'd900, 10'd3, 1'b0, 1'b0);
        send_sample(33'd300, 10'd4, 1'b0, 1'b1);


        wait (peak_valid);

        @(negedge clk);

        $display(
            "Frame 1 peak magnitude = %0d, bin = %0d",
            peak_magnitude,
            peak_bin
        );

        if (
            peak_magnitude == 33'd900
            && peak_bin == 10'd3
        ) begin
            $display("PASS: Frame 1");
        end
        else begin
            $display("FAIL: Frame 1");
        end


        // Second frame:
        // 40, 80, 20
        // Expected peak = 80 at bin 1.

        send_sample(33'd40, 10'd0, 1'b1, 1'b0);
        send_sample(33'd80, 10'd1, 1'b0, 1'b0);
        send_sample(33'd20, 10'd2, 1'b0, 1'b1);


        wait (peak_valid);

        @(negedge clk);

        $display(
            "Frame 2 peak magnitude = %0d, bin = %0d",
            peak_magnitude,
            peak_bin
        );

        if (
            peak_magnitude == 33'd80
            && peak_bin == 10'd1
        ) begin
            $display("PASS: Frame 2");
        end
        else begin
            $display("FAIL: Frame 2");
        end


        $finish;

    end


    task send_sample(
        input logic [32:0] sample_magnitude,
        input logic [9:0]  sample_bin,
        input logic        sample_start,
        input logic        sample_end
    );
        begin

            @(negedge clk);

            magnitude_in = sample_magnitude;
            bin_index = sample_bin;

            frame_start = sample_start;
            frame_end = sample_end;

            input_valid = 1'b1;


            @(negedge clk);

            input_valid = 1'b0;
            frame_start = 1'b0;
            frame_end = 1'b0;

        end
    endtask

endmodule