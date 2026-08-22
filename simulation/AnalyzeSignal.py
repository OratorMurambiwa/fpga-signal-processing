"""Analyze the frequency content of original and filtered signals."""

import matplotlib.pyplot as plt
import numpy as np

from FilterSignal import FilterSignal
from GenerateSignal import GenerateSignal


class AnalyzeSignal:
    """Analyze and display the frequency content of signals."""

    def __init__(self, sample_rate=20_000):
        """Initialize the signal analyzer settings."""
        self.sample_rate = sample_rate

    def compute_fft(self, signal):
        """Compute the frequencies and normalized FFT magnitudes."""
        number_of_samples = len(signal)

        fft_values = np.fft.fft(signal)

        frequencies = np.fft.fftfreq(
            number_of_samples,
            d=1 / self.sample_rate,
        )

        positive_half = number_of_samples // 2

        frequencies = frequencies[:positive_half]

        magnitudes = (
            2
            * np.abs(fft_values[:positive_half])
            / number_of_samples
        )

        return frequencies, magnitudes

    def detect_peaks(
        self,
        frequencies,
        magnitudes,
        threshold=0.1,
    ):
        """Return frequencies with magnitudes above the threshold."""
        peak_indices = np.where(magnitudes > threshold)[0]

        peak_frequencies = frequencies[peak_indices]
        peak_magnitudes = magnitudes[peak_indices]

        return peak_frequencies, peak_magnitudes

    def print_peaks(
        self,
        label,
        peak_frequencies,
        peak_magnitudes,
    ):
        """Print the detected peaks for a signal."""
        print(f"\n{label}")

        for frequency, magnitude in zip(
            peak_frequencies,
            peak_magnitudes,
        ):
            print(
                f"Peak detected: {frequency:.0f} Hz "
                f"(Magnitude: {magnitude:.2f})"
            )

    def plot_spectrums(
        self,
        frequencies,
        original_magnitudes,
        filtered_magnitudes,
    ):
        """Plot the original and filtered frequency spectra."""
        plt.plot(
            frequencies,
            original_magnitudes,
            label="Original Signal",
        )

        plt.plot(
            frequencies,
            filtered_magnitudes,
            label="Filtered Signal",
        )

        plt.xlabel("Frequency (Hz)")
        plt.ylabel("Magnitude")
        plt.title("Original and FIR-Filtered Frequency Spectrum")
        plt.legend()
        plt.grid()
        plt.show()


def main():
    """Generate, filter, and analyze a synthetic signal."""
    signal_generator = GenerateSignal()
    original_signal = signal_generator.generate()

    signal_filter = FilterSignal()
    filtered_signal = signal_filter.apply_filter(
        original_signal
    )

    signal_analyzer = AnalyzeSignal()

    frequencies, original_magnitudes = (
        signal_analyzer.compute_fft(
            original_signal
        )
    )

    _, filtered_magnitudes = signal_analyzer.compute_fft(
        filtered_signal
    )

    original_peak_frequencies, original_peak_magnitudes = (
        signal_analyzer.detect_peaks(
            frequencies,
            original_magnitudes,
        )
    )

    filtered_peak_frequencies, filtered_peak_magnitudes = (
        signal_analyzer.detect_peaks(
            frequencies,
            filtered_magnitudes,
        )
    )

    signal_analyzer.print_peaks(
        "Original Signal Peaks",
        original_peak_frequencies,
        original_peak_magnitudes,
    )

    signal_analyzer.print_peaks(
        "Filtered Signal Peaks",
        filtered_peak_frequencies,
        filtered_peak_magnitudes,
    )

    signal_analyzer.plot_spectrums(
        frequencies,
        original_magnitudes,
        filtered_magnitudes,
    )


if __name__ == "__main__":
    main()