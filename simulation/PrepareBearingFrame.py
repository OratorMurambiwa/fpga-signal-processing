"""Prepare one 1024-sample bearing frame for FPGA simulation."""

from pathlib import Path

import numpy as np


INPUT_FILE = Path("simulation/data/bearing_channel_1.txt")
OUTPUT_FILE = Path("simulation/data/bearing_samples.txt")

FRAME_SIZE = 1024
INT16_MAX = 32767


def main() -> None:
    """Create one normalized 16-bit FPGA input frame."""
    signal = np.loadtxt(INPUT_FILE)

    frame = signal[:FRAME_SIZE]

    peak = np.max(np.abs(frame))

    if peak == 0:
        quantized = np.zeros(FRAME_SIZE, dtype=np.int16)
    else:
        normalized = frame / peak
        quantized = np.round(normalized * INT16_MAX).astype(np.int16)

    np.savetxt(
        OUTPUT_FILE,
        quantized,
        fmt="%d",
    )

    print(f"Input samples loaded: {len(signal)}")
    print(f"Frame samples: {len(quantized)}")
    print(f"Minimum value: {quantized.min()}")
    print(f"Maximum value: {quantized.max()}")
    print(f"Saved to: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()