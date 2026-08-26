"""Extract one bearing vibration channel from an IMS data file."""

from pathlib import Path

import numpy as np


INPUT_FILE = Path(
    r"C:\Users\muram\Downloads\nasa bearing dataset"
    r"\1st_test\1st_test\2003.11.25.13.07.32"
)

OUTPUT_FILE = Path("simulation/data/bearing_channel_1.txt")


def main() -> None:
    """Extract the first vibration channel."""
    data = np.loadtxt(INPUT_FILE)

    channel_1 = data[:, 0]

    OUTPUT_FILE.parent.mkdir(parents=True, exist_ok=True)

    np.savetxt(
        OUTPUT_FILE,
        channel_1,
        fmt="%.6f",
    )

    print(f"Rows loaded: {data.shape[0]}")
    print(f"Columns loaded: {data.shape[1]}")
    print(f"Channel samples saved: {len(channel_1)}")
    print(f"Saved to: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()