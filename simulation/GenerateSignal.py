"""Generate a synthetic noisy signal for FPGA simulation."""

import numpy as np
import matplotlib.pyplot as plt


class GenerateSignal:
    """Generate and display a synthetic signal with added noise."""

    def __init__(self, sample_rate=20_000, duration=1.0):
        """Initialize the signal settings."""
        self.sample_rate = sample_rate
        self.duration = duration
        self.time = np.arange(0, duration, 1 / sample_rate)

    def generate(self):
        """Generate a 1 kHz and 5 kHz signal with random noise."""
        signal_1 = np.sin(2 * np.pi * 1_000 * self.time)
        signal_2 = 0.5 * np.sin(2 * np.pi * 5_000 * self.time)

        clean_signal = signal_1 + signal_2
        noise = 0.2 * np.random.randn(len(self.time))

        return clean_signal + noise

    def plot(self, signal):
        """Plot the first 200 samples of the signal."""
        plt.plot(self.time[:200], signal[:200])
        plt.xlabel("Time (seconds)")
        plt.ylabel("Amplitude")
        plt.title("1 kHz + 5 kHz Signal with Noise")
        plt.grid()
        plt.show()


def main():
    """Generate and plot a sample signal."""
    signal_generator = GenerateSignal()
    signal = signal_generator.generate()
    signal_generator.plot(signal)


if __name__ == "__main__":
    main()
