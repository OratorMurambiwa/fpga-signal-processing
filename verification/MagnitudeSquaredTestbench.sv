// Test the magnitude squared block.

`timescale 1ns / 1ps

module MagnitudeSquaredTestbench;

    logic signed [15:0] real_in;
    logic signed [15:0] imag_in;
    logic        [32:0] magnitude_squared;


    MagnitudeSquared dut (
        .real_in(real_in),
        .imag_in(imag_in),
        .magnitude_squared(magnitude_squared)
    );


    initial begin

        // Test a normal positive value.
        real_in = 16'sd3000;
        imag_in = 16'sd1500;

        #10;

        $display(
            "real = %0d, imag = %0d, magnitude_squared = %0d",
            real_in,
            imag_in,
            magnitude_squared
        );

        if (magnitude_squared == 33'd11250000)
            $display("PASS");
        else
            $display("FAIL");


        // Test a negative real value.
        real_in = -16'sd2000;
        imag_in = 16'sd1000;

        #10;

        $display(
            "real = %0d, imag = %0d, magnitude_squared = %0d",
            real_in,
            imag_in,
            magnitude_squared
        );

        if (magnitude_squared == 33'd5000000)
            $display("PASS");
        else
            $display("FAIL");


        // Test the largest 16-bit magnitude.
        real_in = 16'sh8000;
        imag_in = 16'sh8000;

        #10;

        $display(
            "real = %0d, imag = %0d, magnitude_squared = %0d",
            real_in,
            imag_in,
            magnitude_squared
        );

        if (magnitude_squared == 33'd2147483648)
            $display("PASS");
        else
            $display("FAIL");


        $finish;

    end

endmodule