"""Compare the bearing vibration spectrum with the FPGA result."""

from pathlib import Path

import numpy as np


INPUT_FILE = Path("simulation/data/bearing_samples.txt")

SAMPLE_RATE = 20_000
FFT_SIZE = 1024


def main() -> None:
    """Find the dominant FFT bin and frequency."""
    samples = np.loadtxt(INPUT_FILE)

    fft_result = np.fft.fft(samples, n=FFT_SIZE)
    magnitude_squared = (
        fft_result.real ** 2
        + fft_result.imag ** 2
    )

    positive_half = magnitude_squared[: FFT_SIZE // 2]

    peak_bin = int(np.argmax(positive_half))
    peak_frequency = peak_bin * SAMPLE_RATE / FFT_SIZE
    peak_magnitude = positive_half[peak_bin]

    print(f"Python peak bin: {peak_bin}")
    print(f"Python peak frequency: {peak_frequency:.2f} Hz")
    print(f"Python peak magnitude squared: {peak_magnitude:.0f}")


if __name__ == "__main__":
    main()