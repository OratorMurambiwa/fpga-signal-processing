// Test the full signal-processing pipeline with backpressure.

`timescale 1ns / 1ps

module FullPipelineTestbench;

    logic clk;
    logic reset;

    // FIR signals.
    logic signed [15:0] fir_input_data;
    logic               fir_input_valid;
    logic               fir_input_ready;

    logic signed [15:0] fir_output_data;
    logic               fir_output_valid;

    // FFT setup signals.
    logic [15:0] fft_config_data;
    logic        fft_config_valid;
    logic        fft_config_ready;

    // FFT input signals.
    logic [31:0] fft_input_data;
    logic        fft_input_valid;
    logic        fft_input_ready;
    logic        fft_input_last;

    // FFT output signals.
    logic [31:0] fft_output_data;
    logic        fft_output_valid;
    logic        fft_output_ready;
    logic        fft_output_last;

    // Final peak result.
    logic        peak_valid;
    logic [9:0]  peak_bin;
    logic [32:0] peak_magnitude;

    integer input_file;
    integer scan_result;
    integer sample;
    integer input_count;

    logic [9:0] fft_input_count;


    // Run the input through the FIR first.
    FirFilter fir_filter (
        .clk(clk),
        .reset(reset),

        .input_valid(fir_input_valid),
        .input_ready(fir_input_ready),
        .input_data(fir_input_data),

        .output_valid(fir_output_valid),
        .output_ready(fft_input_ready),
        .output_data(fir_output_data)
    );


    // Run the filtered samples through the FFT.
    FftCore fft_core (
        .aclk(clk),

        .s_axis_config_tdata(fft_config_data),
        .s_axis_config_tvalid(fft_config_valid),
        .s_axis_config_tready(fft_config_ready),

        .s_axis_data_tdata(fft_input_data),
        .s_axis_data_tvalid(fft_input_valid),
        .s_axis_data_tready(fft_input_ready),
        .s_axis_data_tlast(fft_input_last),

        .m_axis_data_tdata(fft_output_data),
        .m_axis_data_tvalid(fft_output_valid),
        .m_axis_data_tready(fft_output_ready),
        .m_axis_data_tlast(fft_output_last),

        .event_frame_started(),
        .event_tlast_unexpected(),
        .event_tlast_missing(),
        .event_status_channel_halt(),
        .event_data_in_channel_halt(),
        .event_data_out_channel_halt()
    );


    // Find the magnitude and strongest FFT bin.
    FrequencyAnalysisPipeline analysis_pipeline (
        .clk(clk),
        .reset(reset),

        .fft_data(fft_output_data),
        .fft_valid(fft_output_valid),
        .fft_ready(fft_output_ready),
        .fft_last(fft_output_last),

        .peak_valid(peak_valid),
        .peak_bin(peak_bin),
        .peak_magnitude(peak_magnitude)
    );


    // Send the filtered sample into the real side of the FFT.
    assign fft_input_data[15:0] = fir_output_data;
    assign fft_input_data[31:16] = 16'sd0;

    assign fft_input_valid = fir_output_valid;


    // Tell the FFT when the last sample in the frame arrives.
    assign fft_input_last =
        fir_output_valid
        && (fft_input_count == 10'd1023);


    // 100 MHz clock.
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end


    // Keep track of how many samples enter the FFT.
    always_ff @(posedge clk) begin

        if (reset) begin

            fft_input_count <= 10'd0;

        end
        else if (fft_input_valid && fft_input_ready) begin

            if (fft_input_last) begin
                fft_input_count <= 10'd0;
            end
            else begin
                fft_input_count <= fft_input_count + 10'd1;
            end

        end

    end


    initial begin

        reset = 1'b1;

        fir_input_data = 16'sd0;
        fir_input_valid = 1'b0;

        fft_config_data = 16'd0;
        fft_config_valid = 1'b0;

        fft_output_ready = 1'b1;

        input_count = 0;


        input_file = $fopen(
            "C:/Users/muram/fpga-signal-processing/simulation/data/signal_samples.txt",
            "r"
        );


        if (input_file == 0) begin
            $display("ERROR: Could not open input file.");
            $finish;
        end


        repeat (5) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;


        send_fft_configuration();


        // Send one full FFT frame.
        while (!$feof(input_file) && input_count < 1024) begin

            scan_result = $fscanf(
                input_file,
                "%d\n",
                sample
            );

            if (scan_result == 1) begin

                send_sample(sample);
                input_count = input_count + 1;

            end

        end


        $fclose(input_file);


        // Wait until FFT output starts.
        wait (fft_output_valid == 1'b1);

        @(negedge clk);

        $display("Applying FFT output backpressure.");

        fft_output_ready = 1'b0;


        // Stall FFT output for 10 clock cycles.
        repeat (10) begin
            @(posedge clk);
        end


        @(negedge clk);

        fft_output_ready = 1'b1;

        $display("Releasing FFT output backpressure.");


        // Wait for the strongest frequency result.
        wait (peak_valid == 1'b1);

        @(negedge clk);


        $display(
            "Full pipeline peak bin = %0d",
            peak_bin
        );

        $display(
            "Full pipeline peak magnitude = %0d",
            peak_magnitude
        );


        if (
            peak_bin == 10'd51
            || peak_bin == 10'd52
        ) begin

            $display(
                "PASS: Full pipeline survived backpressure."
            );

        end
        else begin

            $display(
                "FAIL: Unexpected peak bin after backpressure."
            );

        end


        repeat (10) @(posedge clk);

        $finish;

    end


    // Use the same FFT settings as before.
    task send_fft_configuration;
        begin

            @(negedge clk);

            fft_config_data = 16'h0557;
            fft_config_valid = 1'b1;


            while (!fft_config_ready) begin
                @(negedge clk);
            end


            @(negedge clk);

            fft_config_valid = 1'b0;

        end
    endtask


    // Hold valid until the FIR accepts the sample.
    task send_sample(
        input logic signed [15:0] sample_value
    );
        begin

            @(negedge clk);

            fir_input_data = sample_value;
            fir_input_valid = 1'b1;


            do begin
                @(posedge clk);
            end
            while (!fir_input_ready);


            @(negedge clk);

            fir_input_valid = 1'b0;

        end
    endtask

endmodule