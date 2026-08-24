// Test the peak detector and configurable threshold.

`timescale 1ns / 1ps

module PeakDetectorTestbench;

    logic        clk;
    logic        reset;

    logic        input_valid;
    logic [32:0] magnitude_in;
    logic [9:0]  bin_index;

    logic        frame_start;
    logic        frame_end;

    logic [31:0] threshold;

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

        .threshold(threshold),

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

        threshold = 32'd0;


        repeat (3) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;


        // Frame 1.
        send_sample(
            33'd100,
            10'd0,
            1'b1,
            1'b0
        );

        send_sample(
            33'd500,
            10'd1,
            1'b0,
            1'b0
        );

        send_sample(
            33'd300,
            10'd2,
            1'b0,
            1'b0
        );

        send_sample(
            33'd900,
            10'd3,
            1'b0,
            1'b1
        );


        wait (peak_valid == 1'b1);

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


        @(posedge clk);


        // Frame 2.
        send_sample(
            33'd40,
            10'd0,
            1'b1,
            1'b0
        );

        send_sample(
            33'd80,
            10'd1,
            1'b0,
            1'b0
        );

        send_sample(
            33'd60,
            10'd2,
            1'b0,
            1'b1
        );


        wait (peak_valid == 1'b1);

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


        @(posedge clk);


        // Threshold below the peak.
        threshold = 32'd500;


        send_sample(
            33'd200,
            10'd0,
            1'b1,
            1'b0
        );

        send_sample(
            33'd700,
            10'd1,
            1'b0,
            1'b0
        );

        send_sample(
            33'd400,
            10'd2,
            1'b0,
            1'b1
        );


        wait (peak_valid == 1'b1);

        if (
            peak_magnitude == 33'd700
            && peak_bin == 10'd1
        ) begin

            $display(
                "PASS: Peak above threshold was detected."
            );

        end
        else begin

            $display(
                "FAIL: Peak above threshold was incorrect."
            );

        end


        @(posedge clk);


        // Threshold above the peak.
        threshold = 32'd1000;


        send_sample(
            33'd200,
            10'd0,
            1'b1,
            1'b0
        );

        send_sample(
            33'd700,
            10'd1,
            1'b0,
            1'b0
        );

        send_sample(
            33'd400,
            10'd2,
            1'b0,
            1'b1
        );


        // Peak should not be reported.
        repeat (3) @(posedge clk);


        if (!peak_valid) begin

            $display(
                "PASS: Peak below threshold was rejected."
            );

        end
        else begin

            $display(
                "FAIL: Peak below threshold was detected."
            );

        end


        repeat (5) @(posedge clk);

        $finish;

    end


    // Send one magnitude sample.
    task send_sample(
        input logic [32:0] magnitude,
        input logic [9:0]  bin,
        input logic        start_frame,
        input logic        end_frame
    );
        begin

            @(negedge clk);

            magnitude_in = magnitude;
            bin_index = bin;

            frame_start = start_frame;
            frame_end = end_frame;

            input_valid = 1'b1;


            @(negedge clk);

            input_valid = 1'b0;
            frame_start = 1'b0;
            frame_end = 1'b0;

        end
    endtask

endmodule