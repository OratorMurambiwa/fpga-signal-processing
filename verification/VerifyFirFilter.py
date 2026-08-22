"""Compare Python FIR results with SystemVerilog FIR results."""

from pathlib import Path

import numpy as np


class VerifyFirFilter:
    """Verify RTL FIR output against a Python reference model."""

    def __init__(self):
        """Initialize the FIR coefficients and file paths."""
        self.coefficients = [
            1638,
            3277,
            6554,
            9830,
            6554,
            3277,
            1638,
        ]

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
            / "rtl_filtered_samples.txt"
        )

    def load_samples(self, file_path):
        """Load integer signal samples from a text file."""
        return np.loadtxt(
            file_path,
            dtype=np.int64,
        )

    def compute_reference(self, input_samples):
        """Compute the expected fixed-point FIR output."""
        delay_line = [0] * 6
        reference_output = []

        for sample in input_samples:
            products = [
                int(sample) * self.coefficients[0],
                delay_line[0] * self.coefficients[1],
                delay_line[1] * self.coefficients[2],
                delay_line[2] * self.coefficients[3],
                delay_line[3] * self.coefficients[4],
                delay_line[4] * self.coefficients[5],
                delay_line[5] * self.coefficients[6],
            ]

            total = sum(products)

            filtered_sample = total >> 15

            reference_output.append(filtered_sample)

            delay_line[5] = delay_line[4]
            delay_line[4] = delay_line[3]
            delay_line[3] = delay_line[2]
            delay_line[2] = delay_line[1]
            delay_line[1] = delay_line[0]
            delay_line[0] = int(sample)

        return np.array(
            reference_output,
            dtype=np.int64,
        )

    def compare_outputs(self, reference_output, rtl_output):
        """Compare reference and RTL outputs and print error results."""
        if len(reference_output) != len(rtl_output):
            print("Sample count mismatch.")
            print(
                f"Python samples: {len(reference_output)}"
            )
            print(
                f"RTL samples:    {len(rtl_output)}"
            )
            return

        errors = rtl_output - reference_output

        absolute_errors = np.abs(errors)

        maximum_error = np.max(absolute_errors)
        mean_error = np.mean(absolute_errors)

        mismatched_samples = np.count_nonzero(errors)

        print(f"Samples compared: {len(rtl_output)}")
        print(f"Mismatched samples: {mismatched_samples}")
        print(f"Maximum error: {maximum_error}")
        print(f"Mean absolute error: {mean_error:.6f}")

        if mismatched_samples == 0:
            print("\nPASS: Python and RTL outputs match exactly.")
        else:
            print("\nFAIL: Python and RTL outputs differ.")

            mismatch_indices = np.where(errors != 0)[0]

            print("\nFirst 10 mismatches:")

            for index in mismatch_indices[:10]:
                print(
                    f"Sample {index}: "
                    f"Python={reference_output[index]}, "
                    f"RTL={rtl_output[index]}, "
                    f"Error={errors[index]}"
                )

    def run(self):
        """Load samples, calculate the reference, and verify RTL."""
        input_samples = self.load_samples(
            self.input_file
        )

        rtl_output = self.load_samples(
            self.rtl_output_file
        )

        reference_output = self.compute_reference(
            input_samples
        )

        self.compare_outputs(
            reference_output,
            rtl_output,
        )


def main():
    """Run the FIR filter verification."""
    verifier = VerifyFirFilter()
    verifier.run()


if __name__ == "__main__":
    main()