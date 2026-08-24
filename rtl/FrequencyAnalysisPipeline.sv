// Convert FFT output into magnitude and find the strongest bin.

module FrequencyAnalysisPipeline (
    input  logic        clk,
    input  logic        reset,

    // FFT output stream.
    input  logic [31:0] fft_data,
    input  logic        fft_valid,
    output logic        fft_ready,
    input  logic        fft_last,

    // Configurable peak threshold.
    input  logic [31:0] threshold,

    // Final peak result.
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


    // The lower half contains the real component.
    assign fft_real = fft_data[15:0];

    // The upper half contains the imaginary component.
    assign fft_imag = fft_data[31:16];


    // This stage can currently accept one FFT sample every clock.
    assign fft_ready = 1'b1;


    // Calculate the strength of the complex FFT sample.
    MagnitudeSquared magnitude_squared_unit (
        .real_in(fft_real),
        .imag_in(fft_imag),
        .magnitude_squared(magnitude_squared)
    );


    // The first accepted FFT sample starts a frame.
    assign frame_start =
        fft_valid
        && fft_ready
        && (bin_index == 10'd0);


    // TLAST marks the final FFT sample.
    assign frame_end =
        fft_valid
        && fft_ready
        && fft_last;


    // Track the FFT bin number.
    always_ff @(posedge clk) begin

        if (reset) begin

            bin_index <= 10'd0;

        end
        else if (fft_valid && fft_ready) begin

            if (fft_last) begin
                bin_index <= 10'd0;
            end
            else begin
                bin_index <= bin_index + 10'd1;
            end

        end

    end


    // Find the strongest FFT bin above the configured threshold.
    PeakDetector peak_detector (
        .clk(clk),
        .reset(reset),

        .input_valid(
            fft_valid
            && fft_ready
        ),

        .magnitude_in(magnitude_squared),
        .bin_index(bin_index),

        .frame_start(frame_start),
        .frame_end(frame_end),

        .threshold(threshold),

        .peak_valid(peak_valid),
        .peak_bin(peak_bin),
        .peak_magnitude(peak_magnitude)
    );

endmodule