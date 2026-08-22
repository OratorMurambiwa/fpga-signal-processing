// Compute magnitude squared from a complex FFT sample.

module MagnitudeSquared (
    input  logic signed [15:0] real_in,
    input  logic signed [15:0] imag_in,
    output logic        [32:0] magnitude_squared
);

    logic signed [31:0] real_product;
    logic signed [31:0] imag_product;

    always_comb begin

        real_product = real_in * real_in;
        imag_product = imag_in * imag_in;

        magnitude_squared =
            {1'b0, real_product[31:0]}
            + {1'b0, imag_product[31:0]};

    end

endmodule