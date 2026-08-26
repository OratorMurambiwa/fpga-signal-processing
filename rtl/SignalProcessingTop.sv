// Top-level signal-processing accelerator.

module SignalProcessingTop (
    input logic clk,
    input logic reset,

    // Input sample stream.
    input  logic signed [15:0] sample_data,
    input  logic               sample_valid,
    output logic               sample_ready,

    // AXI4-Lite write address channel.
    input  logic [3:0]  s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    // AXI4-Lite write data channel.
    input  logic [31:0] s_axi_wdata,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    // AXI4-Lite write response channel.
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    // AXI4-Lite read address channel.
    input  logic [3:0]  s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // AXI4-Lite read data channel.
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // Final frequency result.
    output logic        peak_valid,
    output logic [9:0]  peak_bin,
    output logic [32:0] peak_magnitude
);

    logic signed [15:0] fir_output_data;
    logic               fir_output_valid;

    logic [23:0] fft_config_data;
    logic        fft_config_valid;
    logic        fft_config_ready;

    logic [31:0] fft_input_data;
    logic        fft_input_valid;
    logic        fft_input_ready;
    logic        fft_input_last;

    logic [31:0] fft_output_data;
    logic        fft_output_valid;
    logic        fft_output_ready;
    logic        fft_output_last;

    logic [31:0] threshold;
    logic [9:0]  fft_input_count;

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

    FirFilter fir_filter (
        .clk(clk),
        .reset(reset),

        .input_valid(sample_valid),
        .input_ready(sample_ready),
        .input_data(sample_data),

        .output_valid(fir_output_valid),
        .output_ready(fft_input_ready),
        .output_data(fir_output_data)
    );

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

    // Place the real FIR value in the lower half of the complex FFT input.
    assign fft_input_data[15:0] = fir_output_data;
    assign fft_input_data[31:16] = 16'sd0;

    assign fft_input_valid = fir_output_valid;

    // Mark the final accepted sample in each 1024-point frame.
    assign fft_input_last =
        fft_input_valid
        && (fft_input_count == 10'd1023);

    // Forward FFT with a 20-bit Radix-2 scaling schedule.
    assign fft_config_data = 24'h0AAAAD;

    // Send the FFT configuration once after reset.
    always_ff @(posedge clk) begin
        if (reset) begin
            fft_config_valid <= 1'b1;
        end
        else if (
            fft_config_valid
            && fft_config_ready
        ) begin
            fft_config_valid <= 1'b0;
        end
    end

    // Count samples actually accepted by the FFT.
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

endmodule