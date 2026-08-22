// Compute magnitude squared from a complex FFT sample.

module MagnitudeSquared (
    input  logic signed [15:0] real_in,
    input  logic signed [15:0] imag_in,
    output logic        [32:0] magnitude_squared
);

    logic [31:0] real_squared;
    logic [31:0] imag_squared;

    always_comb begin

        real_squared = $unsigned(real_in * real_in);
        imag_squared = $unsigned(imag_in * imag_in);

        magnitude_squared =
            {1'b0, real_squared}
            + {1'b0, imag_squared};

    end

endmodule