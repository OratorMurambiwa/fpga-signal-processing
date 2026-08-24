// Test the full signal-processing pipeline with AXI4-Lite control.

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


    // FFT configuration signals.
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


    // AXI4-Lite write address channel.
    logic [3:0]  s_axi_awaddr;
    logic        s_axi_awvalid;
    logic        s_axi_awready;


    // AXI4-Lite write data channel.
    logic [31:0] s_axi_wdata;
    logic        s_axi_wvalid;
    logic        s_axi_wready;


    // AXI4-Lite write response channel.
    logic [1:0]  s_axi_bresp;
    logic        s_axi_bvalid;
    logic        s_axi_bready;


    // AXI4-Lite read address channel.
    logic [3:0]  s_axi_araddr;
    logic        s_axi_arvalid;
    logic        s_axi_arready;


    // AXI4-Lite read data channel.
    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;


    // Configuration register.
    logic [31:0] threshold;


    // Final peak result.
    logic        peak_valid;
    logic [9:0]  peak_bin;
    logic [32:0] peak_magnitude;


    integer input_file;
    integer scan_result;
    integer sample;
    integer input_count;

    logic [9:0] fft_input_count;


    // Store the configurable threshold through AXI4-Lite.
    AxiLiteControl axi_lite_control (
        .clk(clk),
        .reset(reset),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),

        .threshold(threshold)
    );


    // Filter the input samples.
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


    // Convert the filtered samples into frequency data.
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


    // Calculate magnitudes and find the strongest frequency.
    FrequencyAnalysisPipeline analysis_pipeline (
        .clk(clk),
        .reset(reset),

        .fft_data(fft_output_data),
        .fft_valid(fft_output_valid),
        .fft_ready(fft_output_ready),
        .fft_last(fft_output_last),

        .threshold(threshold),

        .peak_valid(peak_valid),
        .peak_bin(peak_bin),
        .peak_magnitude(peak_magnitude)
    );


    // Send the FIR result into the real side of the FFT.
    assign fft_input_data[15:0] = fir_output_data;
    assign fft_input_data[31:16] = 16'sd0;

    assign fft_input_valid = fir_output_valid;


    // Mark the final sample in each 1024-sample FFT frame.
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


    // Count samples accepted by the FFT.
    always_ff @(posedge clk) begin

        if (reset) begin

            fft_input_count <= 10'd0;

        end
        else if (
            fft_input_valid
            && fft_input_ready
        ) begin

            if (fft_input_last) begin

                fft_input_count <= 10'd0;

            end
            else begin

                fft_input_count <=
                    fft_input_count + 10'd1;

            end

        end

    end


    initial begin

        reset = 1'b1;


        // FIR inputs.
        fir_input_data = 16'sd0;
        fir_input_valid = 1'b0;


        // FFT configuration.
        fft_config_data = 16'd0;
        fft_config_valid = 1'b0;


        // AXI4-Lite inputs.
        s_axi_awaddr = 4'd0;
        s_axi_awvalid = 1'b0;

        s_axi_wdata = 32'd0;
        s_axi_wvalid = 1'b0;

        s_axi_bready = 1'b1;

        s_axi_araddr = 4'd0;
        s_axi_arvalid = 1'b0;

        s_axi_rready = 1'b1;


        input_count = 0;


        input_file = $fopen(
            "C:/Users/muram/fpga-signal-processing/simulation/data/signal_samples.txt",
            "r"
        );


        if (input_file == 0) begin

            $display(
                "ERROR: Could not open input file."
            );

            $finish;

        end


        repeat (5) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;


        // Set the detection threshold using AXI4-Lite.
        write_register(
            4'h0,
            32'd5000000
        );


        $display(
            "AXI4-Lite threshold = %0d",
            threshold
        );


        if (threshold == 32'd5000000) begin

            $display(
                "PASS: AXI4-Lite configured the threshold."
            );

        end
        else begin

            $display(
                "FAIL: Threshold configuration failed."
            );

        end


        // Configure the FFT.
        send_fft_configuration();


        // Send one full FFT frame.
        while (
            !$feof(input_file)
            && input_count < 1024
        ) begin

            scan_result = $fscanf(
                input_file,
                "%d\n",
                sample
            );


            if (scan_result == 1) begin

                send_sample(sample);

                input_count =
                    input_count + 1;

            end

        end


        $fclose(input_file);


        // Wait for a peak that passes the threshold.
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
                "PASS: Full pipeline detected the expected frequency."
            );

        end
        else begin

            $display(
                "FAIL: Unexpected peak bin."
            );

        end


        if (
            peak_magnitude
            >= {1'b0, threshold}
        ) begin

            $display(
                "PASS: Peak passed the AXI4-Lite threshold."
            );

        end
        else begin

            $display(
                "FAIL: Peak did not meet the threshold."
            );

        end


        repeat (10) @(posedge clk);

        $finish;

    end


    // Write one AXI4-Lite register.
    task write_register(
        input logic [3:0]  address,
        input logic [31:0] data
    );
        begin

            @(negedge clk);

            s_axi_awaddr = address;
            s_axi_awvalid = 1'b1;

            s_axi_wdata = data;
            s_axi_wvalid = 1'b1;


            do begin
                @(posedge clk);
            end
            while (
                !(
                    s_axi_awready
                    && s_axi_wready
                )
            );


            @(negedge clk);

            s_axi_awvalid = 1'b0;
            s_axi_wvalid = 1'b0;


            wait (s_axi_bvalid == 1'b1);

            @(posedge clk);

        end
    endtask


    // Send the FFT configuration word.
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


    // Hold the input until the FIR accepts it.
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