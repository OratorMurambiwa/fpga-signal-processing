"""Compare AMD FFT output with a NumPy FFT reference."""

from pathlib import Path

import numpy as np


class VerifyFftCore:
    """Verify FPGA FFT frequency bins against a Python reference."""

    def __init__(self, sample_rate=20_000, fft_size=1024):
        """Initialize FFT settings and file paths."""
        self.sample_rate = sample_rate
        self.fft_size = fft_size

        project_root = Path(__file__).resolve().parent.parent

        self.input_file = (
            project_root
            / "simulation"
            / "data"
            / "signal_samples.txt"
        )

        self.rtl_output_file = (
            project_root
            / "simulation"
            / "data"
            / "fft_output_samples.txt"
        )

    def load_input_samples(self):
        """Load the first FFT frame from the input sample file."""
        samples = np.loadtxt(
            self.input_file,
            dtype=np.int64,
        )

        return samples[:self.fft_size]

    def load_rtl_output(self):
        """Load the real and imaginary FPGA FFT outputs."""
        fft_output = np.loadtxt(
            self.rtl_output_file,
            dtype=np.int64,
        )

        real_values = fft_output[:, 0]
        imaginary_values = fft_output[:, 1]

        return real_values, imaginary_values

    def compute_python_fft(self, input_samples):
        """Compute the NumPy FFT reference."""
        return np.fft.fft(input_samples)

    def compute_magnitude(self, real_values, imaginary_values):
        """Compute magnitude from real and imaginary values."""
        return np.sqrt(
            real_values**2 + imaginary_values**2
        )

    def find_strongest_bins(self, magnitudes, number_of_bins=5):
        """Return the strongest positive-frequency FFT bins."""
        positive_half = magnitudes[:self.fft_size // 2]

        strongest_bins = np.argsort(
            positive_half
        )[-number_of_bins:][::-1]

        return strongest_bins

    def bin_to_frequency(self, bin_index):
        """Convert an FFT bin number into frequency in hertz."""
        return (
            bin_index
            * self.sample_rate
            / self.fft_size
        )

    def print_results(
        self,
        label,
        strongest_bins,
        magnitudes,
    ):
        """Print the strongest FFT bins and frequencies."""
        print(f"\n{label}")

        for bin_index in strongest_bins:
            frequency = self.bin_to_frequency(bin_index)

            print(
                f"Bin {bin_index}: "
                f"{frequency:.2f} Hz "
                f"(Magnitude: {magnitudes[bin_index]:.2f})"
            )

    def run(self):
        """Compare Python and FPGA FFT frequency results."""
        input_samples = self.load_input_samples()

        rtl_real, rtl_imaginary = self.load_rtl_output()

        if len(rtl_real) != self.fft_size:
            print(
                f"Expected {self.fft_size} RTL outputs, "
                f"but found {len(rtl_real)}."
            )
            return

        python_fft = self.compute_python_fft(
            input_samples
        )

        python_magnitudes = np.abs(python_fft)

        rtl_magnitudes = self.compute_magnitude(
            rtl_real,
            rtl_imaginary,
        )

        python_bins = self.find_strongest_bins(
            python_magnitudes
        )

        rtl_bins = self.find_strongest_bins(
            rtl_magnitudes
        )

        self.print_results(
            "Python FFT",
            python_bins,
            python_magnitudes,
        )

        self.print_results(
            "FPGA FFT",
            rtl_bins,
            rtl_magnitudes,
        )

        if set(python_bins[:2]) == set(rtl_bins[:2]):
            print(
                "\nPASS: FPGA and Python agree on "
                "the two strongest frequency bins."
            )
        else:
            print(
                "\nCHECK: The strongest FPGA bins "
                "do not exactly match Python."
            )


def main():
    """Run the FFT verification."""
    verifier = VerifyFftCore()
    verifier.run()


if __name__ == "__main__":
    main()