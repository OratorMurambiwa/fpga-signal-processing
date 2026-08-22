// Compute magnitude squared from a complex FFT sample.

module MagnitudeSquared (
    input  logic signed [15:0] real_in,
    input  logic signed [15:0] imag_in,
    output logic        [32:0] magnitude_squared
);

    logic signed [31:0] real_squared;
    logic signed [31:0] imag_squared;

    always_comb begin
        real_squared = real_in * real_in;
        imag_squared = imag_in * imag_in;

        magnitude_squared =
            real_squared + imag_squared;
    end

endmodule