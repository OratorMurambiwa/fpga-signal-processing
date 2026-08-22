"""Apply an FIR filter to a generated signal."""

import matplotlib.pyplot as plt
import numpy as np

from GenerateSignal import GenerateSignal


class FilterSignal:
    """Apply a simple FIR low-pass filter to a signal."""

    def __init__(self):
        """Initialize the FIR filter coefficients."""
        self.coefficients = np.array(
            [
                0.05,
                0.10,
                0.20,
                0.30,
                0.20,
                0.10,
                0.05,
            ]
        )

    def apply_filter(self, signal):
        """Apply the FIR filter to the input signal."""
        filtered_signal = np.convolve(
            signal,
            self.coefficients,
            mode="same",
        )

        return filtered_signal

    def plot_signals(self, time, original_signal, filtered_signal):
        """Plot the original and filtered signals."""
        number_of_samples = 200

        plt.plot(
            time[:number_of_samples],
            original_signal[:number_of_samples],
            label="Original Signal",
        )

        plt.plot(
            time[:number_of_samples],
            filtered_signal[:number_of_samples],
            label="Filtered Signal",
        )

        plt.xlabel("Time (seconds)")
        plt.ylabel("Amplitude")
        plt.title("Original and FIR-Filtered Signal")
        plt.legend()
        plt.grid()
        plt.show()


def main():
    """Generate a signal, filter it, and display the result."""
    signal_generator = GenerateSignal()

    original_signal = signal_generator.generate()

    signal_filter = FilterSignal()

    filtered_signal = signal_filter.apply_filter(
        original_signal
    )

    signal_filter.plot_signals(
        signal_generator.time,
        original_signal,
        filtered_signal,
    )


if __name__ == "__main__":
    main()