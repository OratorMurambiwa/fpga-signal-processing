// Test FFT output through magnitude calculation and peak detection.

`timescale 1ns / 1ps

module FrequencyAnalysisPipelineTestbench;

    logic clk;
    logic reset;

    logic [15:0] s_axis_config_tdata;
    logic        s_axis_config_tvalid;
    logic        s_axis_config_tready;

    logic [31:0] s_axis_data_tdata;
    logic        s_axis_data_tvalid;
    logic        s_axis_data_tready;
    logic        s_axis_data_tlast;

    logic [31:0] m_axis_data_tdata;
    logic        m_axis_data_tvalid;
    logic        m_axis_data_tready;
    logic        m_axis_data_tlast;

    logic peak_valid;
    logic [9:0] peak_bin;
    logic [32:0] peak_magnitude;

    integer input_file;
    integer scan_result;
    integer sample;
    integer sample_count;

    FftCore fft_core (
        .aclk(clk),

        .s_axis_config_tdata(s_axis_config_tdata),
        .s_axis_config_tvalid(s_axis_config_tvalid),
        .s_axis_config_tready(s_axis_config_tready),

        .s_axis_data_tdata(s_axis_data_tdata),
        .s_axis_data_tvalid(s_axis_data_tvalid),
        .s_axis_data_tready(s_axis_data_tready),
        .s_axis_data_tlast(s_axis_data_tlast),

        .m_axis_data_tdata(m_axis_data_tdata),
        .m_axis_data_tvalid(m_axis_data_tvalid),
        .m_axis_data_tready(m_axis_data_tready),
        .m_axis_data_tlast(m_axis_data_tlast),

        .event_frame_started(),
        .event_tlast_unexpected(),
        .event_tlast_missing(),
        .event_status_channel_halt(),
        .event_data_in_channel_halt(),
        .event_data_out_channel_halt()
    );

    FrequencyAnalysisPipeline pipeline (
        .clk(clk),
        .reset(reset),

        .fft_data(m_axis_data_tdata),
        .fft_valid(m_axis_data_tvalid),
        .fft_ready(m_axis_data_tready),
        .fft_last(m_axis_data_tlast),

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

        s_axis_config_tdata = 16'd0;
        s_axis_config_tvalid = 1'b0;

        s_axis_data_tdata = 32'd0;
        s_axis_data_tvalid = 1'b0;
        s_axis_data_tlast = 1'b0;

        m_axis_data_tready = 1'b1;

        sample_count = 0;

        input_file = $fopen(
            "C:/Users/muram/fpga-signal-processing/simulation/data/signal_samples.txt",
            "r"
        );

        if (input_file == 0) begin
            $display("ERROR: Could not open input file.");
            $finish;
        end

        repeat (5) @(posedge clk);

        reset = 1'b0;

        send_configuration();

        while (
            !$feof(input_file)
            && sample_count < 1024
        ) begin
            scan_result = $fscanf(
                input_file,
                "%d\n",
                sample
            );

            if (scan_result == 1) begin
                send_sample(
                    sample,
                    sample_count == 1023
                );

                sample_count = sample_count + 1;
            end
        end

        $fclose(input_file);

        wait (peak_valid == 1'b1);

        $display(
            "Peak bin = %0d, Peak magnitude = %0d",
            peak_bin,
            peak_magnitude
        );

        if (
            peak_bin == 10'd51
            || peak_bin == 10'd52
        ) begin
            $display("PASS");
        end
        else begin
            $display("FAIL");
        end

        repeat (10) @(posedge clk);

        $finish;
    end

    task send_configuration;
        begin
            @(negedge clk);

            s_axis_config_tdata = 16'h0557;
            s_axis_config_tvalid = 1'b1;

            while (!s_axis_config_tready) begin
                @(negedge clk);
            end

            @(negedge clk);

            s_axis_config_tvalid = 1'b0;
        end
    endtask

    task send_sample(
        input logic signed [15:0] sample_value,
        input logic last_sample
    );
        begin
            @(negedge clk);

            while (!s_axis_data_tready) begin
                @(negedge clk);
            end

            s_axis_data_tdata[15:0] = sample_value;
            s_axis_data_tdata[31:16] = 16'sd0;

            s_axis_data_tvalid = 1'b1;
            s_axis_data_tlast = last_sample;

            @(negedge clk);

            s_axis_data_tvalid = 1'b0;
            s_axis_data_tlast = 1'b0;
        end
    endtask

endmodule