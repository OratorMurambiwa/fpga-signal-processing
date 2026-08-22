// Track the strongest magnitude in one FFT frame.

module PeakDetector (
    input  logic        clk,
    input  logic        reset,

    input  logic        input_valid,
    input  logic [32:0] magnitude_in,
    input  logic [9:0]  bin_index,

    input  logic        frame_start,
    input  logic        frame_end,

    output logic        peak_valid,
    output logic [9:0]  peak_bin,
    output logic [32:0] peak_magnitude
);

    logic [32:0] max_magnitude;
    logic [9:0]  max_bin;


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

                // Start a new frame with the first sample.
                if (frame_start) begin

                    max_magnitude <= magnitude_in;
                    max_bin <= bin_index;

                end

                // Update the current maximum.
                else if (magnitude_in > max_magnitude) begin

                    max_magnitude <= magnitude_in;
                    max_bin <= bin_index;

                end


                // Output the final result at the end of the frame.
                if (frame_end) begin

                    if (
                        frame_start
                        || magnitude_in > max_magnitude
                    ) begin

                        peak_magnitude <= magnitude_in;
                        peak_bin <= bin_index;

                    end
                    else begin

                        peak_magnitude <= max_magnitude;
                        peak_bin <= max_bin;

                    end

                    peak_valid <= 1'b1;

                end

            end

        end

    end

endmodule