"""Convert floating-point signal samples into signed 16-bit integers."""

import numpy as np

from GenerateSignal import GenerateSignal


class QuantizeSignal:
    """Convert signal samples into FPGA-friendly integer values."""

    def __init__(self, bit_width=16):
        """Initialize the quantizer settings."""
        self.bit_width = bit_width
        self.maximum_value = (2 ** (bit_width - 1)) - 1
        self.minimum_value = -(2 ** (bit_width - 1))

    def quantize(self, signal):
        """Scale and convert the signal into signed integer samples."""
        maximum_amplitude = np.max(np.abs(signal))

        normalized_signal = signal / maximum_amplitude

        scaled_signal = normalized_signal * self.maximum_value

        rounded_signal = np.round(scaled_signal)

        clipped_signal = np.clip(
            rounded_signal,
            self.minimum_value,
            self.maximum_value,
        )

        quantized_signal = clipped_signal.astype(np.int16)

        return quantized_signal

    def export_signal(self, signal, file_name="signal_samples.txt"):
        """Save quantized signal samples to a text file."""
        np.savetxt(
            file_name,
            signal,
            fmt="%d",
        )


def main():
    """Generate, quantize, and export a synthetic signal."""
    signal_generator = GenerateSignal()
    signal = signal_generator.generate()

    quantizer = QuantizeSignal()
    quantized_signal = quantizer.quantize(signal)

    print("Original samples:")
    print(signal[:10])

    print("\nQuantized samples:")
    print(quantized_signal[:10])

    quantizer.export_signal(
        quantized_signal,
        "signal_samples.txt",
    )

    print("\nSignal samples saved to signal_samples.txt")


if __name__ == "__main__":
    main()