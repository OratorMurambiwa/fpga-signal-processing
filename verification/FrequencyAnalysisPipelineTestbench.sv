// Test the FFT magnitude and peak-detection pipeline.

`timescale 1ns / 1ps

module FrequencyAnalysisPipelineTestbench;

    logic clk;
    logic reset;

    logic [31:0] fft_data;
    logic        fft_valid;
    logic        fft_ready;
    logic        fft_last;

    logic [31:0] threshold;

    logic        peak_valid;
    logic [9:0]  peak_bin;
    logic [32:0] peak_magnitude;


    FrequencyAnalysisPipeline dut (
        .clk(clk),
        .reset(reset),

        .fft_data(fft_data),
        .fft_valid(fft_valid),
        .fft_ready(fft_ready),
        .fft_last(fft_last),

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

        fft_data = 32'd0;
        fft_valid = 1'b0;
        fft_last = 1'b0;

        threshold = 32'd0;


        repeat (3) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;


        // Frame 1.
        // Bin 0: real = 10, imag = 0
        // Magnitude squared = 100
        send_fft_sample(
            16'sd10,
            16'sd0,
            1'b0
        );


        // Bin 1: real = 20, imag = 0
        // Magnitude squared = 400
        send_fft_sample(
            16'sd20,
            16'sd0,
            1'b0
        );


        // Bin 2: real = 30, imag = 0
        // Magnitude squared = 900
        send_fft_sample(
            16'sd30,
            16'sd0,
            1'b0
        );


        // Bin 3: real = 40, imag = 0
        // Magnitude squared = 1600
        send_fft_sample(
            16'sd40,
            16'sd0,
            1'b1
        );


        wait (peak_valid == 1'b1);

        $display(
            "Frame 1 peak magnitude = %0d, bin = %0d",
            peak_magnitude,
            peak_bin
        );


        if (
            peak_magnitude == 33'd1600
            && peak_bin == 10'd3
        ) begin

            $display(
                "PASS: Frame 1 peak detected correctly."
            );

        end
        else begin

            $display(
                "FAIL: Frame 1 peak incorrect."
            );

        end


        @(posedge clk);


        // Frame 2 with a threshold below the peak.
        threshold = 32'd1000;


        // Bin 0: magnitude squared = 100.
        send_fft_sample(
            16'sd10,
            16'sd0,
            1'b0
        );


        // Bin 1: magnitude squared = 2500.
        send_fft_sample(
            16'sd50,
            16'sd0,
            1'b0
        );


        // Bin 2: magnitude squared = 400.
        send_fft_sample(
            16'sd20,
            16'sd0,
            1'b1
        );


        wait (peak_valid == 1'b1);

        $display(
            "Frame 2 peak magnitude = %0d, bin = %0d",
            peak_magnitude,
            peak_bin
        );


        if (
            peak_magnitude == 33'd2500
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


        // Frame 3 with a threshold above the peak.
        threshold = 32'd3000;


        // Bin 0: magnitude squared = 100.
        send_fft_sample(
            16'sd10,
            16'sd0,
            1'b0
        );


        // Bin 1: magnitude squared = 2500.
        send_fft_sample(
            16'sd50,
            16'sd0,
            1'b0
        );


        // Bin 2: magnitude squared = 400.
        send_fft_sample(
            16'sd20,
            16'sd0,
            1'b1
        );


        // No peak should be reported.
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


    // Send one complex FFT sample.
    task send_fft_sample(
        input logic signed [15:0] real_value,
        input logic signed [15:0] imag_value,
        input logic               last_sample
    );
        begin

            @(negedge clk);

            fft_data[15:0] = real_value;
            fft_data[31:16] = imag_value;

            fft_valid = 1'b1;
            fft_last = last_sample;


            do begin
                @(posedge clk);
            end
            while (!fft_ready);


            @(negedge clk);

            fft_valid = 1'b0;
            fft_last = 1'b0;

        end
    endtask

endmodule