// Test the AMD FFT IP core using 1024 real-valued input samples.

`timescale 1ns / 1ps

module FftCoreTestbench;

    logic aclk;

    logic [15:0] s_axis_config_tdata;
    logic s_axis_config_tvalid;
    logic s_axis_config_tready;

    logic [31:0] s_axis_data_tdata;
    logic s_axis_data_tvalid;
    logic s_axis_data_tready;
    logic s_axis_data_tlast;

    logic [31:0] m_axis_data_tdata;
    logic m_axis_data_tvalid;
    logic m_axis_data_tready;
    logic m_axis_data_tlast;

    logic event_frame_started;
    logic event_tlast_unexpected;
    logic event_tlast_missing;
    logic event_status_channel_halt;
    logic event_data_in_channel_halt;
    logic event_data_out_channel_halt;

    integer input_file;
    integer output_file;
    integer scan_result;
    integer sample;
    integer sample_count;

    FftCore dut (
        .aclk(aclk),

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

        .event_frame_started(event_frame_started),
        .event_tlast_unexpected(event_tlast_unexpected),
        .event_tlast_missing(event_tlast_missing),
        .event_status_channel_halt(event_status_channel_halt),
        .event_data_in_channel_halt(event_data_in_channel_halt),
        .event_data_out_channel_halt(event_data_out_channel_halt)
    );

    // Generate a 100 MHz clock.
    initial begin
        aclk = 1'b0;

        forever begin
            #5 aclk = ~aclk;
        end
    end

    // Configure and feed one 1024-sample FFT frame.
    initial begin
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

        output_file = $fopen(
            "C:/Users/muram/fpga-signal-processing/simulation/data/fft_output_samples.txt",
            "w"
        );

        if (input_file == 0) begin
            $display("Error: Could not open input sample file.");
            $finish;
        end

        if (output_file == 0) begin
            $display("Error: Could not open FFT output file.");
            $finish;
        end

        // Wait for the FFT core to initialize.
        repeat (5) begin
            @(posedge aclk);
        end

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

        wait (m_axis_data_tlast == 1'b1);

        repeat (10) begin
            @(posedge aclk);
        end

        $fclose(output_file);

        $finish;
    end

    // Send FFT configuration before the frame begins.
    task send_configuration;
        begin
            @(negedge aclk);

            s_axis_config_tdata = 16'h02AA;
            s_axis_config_tvalid = 1'b1;

            while (!s_axis_config_tready) begin
                @(negedge aclk);
            end

            @(negedge aclk);

            s_axis_config_tvalid = 1'b0;
        end
    endtask

    // Send one real-valued sample to the FFT.
    task send_sample(
        input logic signed [15:0] sample_value,
        input logic last_sample
    );
        begin
            @(negedge aclk);

            while (!s_axis_data_tready) begin
                @(negedge aclk);
            end

            s_axis_data_tdata[15:0] = sample_value;
            s_axis_data_tdata[31:16] = 16'sd0;

            s_axis_data_tvalid = 1'b1;
            s_axis_data_tlast = last_sample;

            @(negedge aclk);

            s_axis_data_tvalid = 1'b0;
            s_axis_data_tlast = 1'b0;
        end
    endtask

    // Save every valid complex FFT output.
    always @(negedge aclk) begin
        if (m_axis_data_tvalid && m_axis_data_tready) begin
            $fdisplay(
                output_file,
                "%0d %0d",
                $signed(m_axis_data_tdata[15:0]),
                $signed(m_axis_data_tdata[31:16])
            );
        end
    end

endmodule