// Connect the FFT output to magnitude calculation and peak detection.

module FrequencyAnalysisPipeline (
    input  logic        clk,
    input  logic        reset,

    input  logic [31:0] fft_data,
    input  logic        fft_valid,
    input  logic        fft_ready,
    input  logic        fft_last,

    output logic        peak_valid,
    output logic [9:0]  peak_bin,
    output logic [32:0] peak_magnitude
);

    logic signed [15:0] fft_real;
    logic signed [15:0] fft_imag;

    logic [32:0] magnitude_squared;

    logic [9:0] bin_index;

    logic frame_start;
    logic frame_end;
    logic sample_accepted;

    assign fft_real = fft_data[15:0];
    assign fft_imag = fft_data[31:16];

    assign sample_accepted = fft_valid && fft_ready;

    assign frame_start =
        sample_accepted && (bin_index == 10'd0);

    assign frame_end =
        sample_accepted && fft_last;

    MagnitudeSquared magnitude_unit (
        .real_in(fft_real),
        .imag_in(fft_imag),
        .magnitude_squared(magnitude_squared)
    );

    PeakDetector peak_detector (
        .clk(clk),
        .reset(reset),
        .input_valid(sample_accepted),
        .frame_start(frame_start),
        .frame_end(frame_end),
        .magnitude_in(magnitude_squared),
        .bin_index(bin_index),

        .peak_valid(peak_valid),
        .peak_bin(peak_bin),
        .peak_magnitude(peak_magnitude)
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            bin_index <= 10'd0;
        end
        else if (sample_accepted) begin
            if (fft_last) begin
                bin_index <= 10'd0;
            end
            else begin
                bin_index <= bin_index + 10'd1;
            end
        end
    end

endmodule