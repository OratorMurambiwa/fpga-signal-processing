// Track the strongest magnitude in one FFT frame.

module PeakDetector (
    input  logic        clk,
    input  logic        reset,

    input  logic        input_valid,
    input  logic [32:0] magnitude_in,
    input  logic [9:0]  bin_index,

    input  logic        frame_start,
    input  logic        frame_end,

    // Configurable detection threshold.
    input  logic [31:0] threshold,

    output logic        peak_valid,
    output logic [9:0]  peak_bin,
    output logic [32:0] peak_magnitude
);

    logic [32:0] max_magnitude;
    logic [9:0]  max_bin;

    logic [32:0] final_magnitude;
    logic [9:0]  final_bin;


    always_comb begin

        // Normally use the largest value already stored.
        final_magnitude = max_magnitude;
        final_bin = max_bin;

        // The final FFT sample might itself be the largest.
        if (
            frame_start
            || magnitude_in > max_magnitude
        ) begin
            final_magnitude = magnitude_in;
            final_bin = bin_index;
        end

    end


    always_ff @(posedge clk) begin

        if (reset) begin

            max_magnitude <= 33'd0;
            max_bin <= 10'd0;

            peak_valid <= 1'b0;
            peak_bin <= 10'd0;
            peak_magnitude <= 33'd0;

        end
        else begin

            peak_valid <= 1'b0;


            if (input_valid) begin

                // Start a new frame.
                if (frame_start) begin

                    max_magnitude <= magnitude_in;
                    max_bin <= bin_index;

                end

                // Update the strongest sample.
                else if (magnitude_in > max_magnitude) begin

                    max_magnitude <= magnitude_in;
                    max_bin <= bin_index;

                end


                // Check the strongest result at the end of the frame.
                if (frame_end) begin

                    peak_magnitude <= final_magnitude;
                    peak_bin <= final_bin;


                    if (
                        final_magnitude
                        >= {1'b0, threshold}
                    ) begin

                        peak_valid <= 1'b1;

                    end

                end

            end

        end

    end

endmodule