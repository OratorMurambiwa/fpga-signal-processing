from pathlib import Path

from cocotb_tools.runner import get_runner


def run_test():
    """Build and run the magnitude squared Cocotb tests."""

    project_root = Path(__file__).resolve().parents[2]

    rtl_file = project_root / "rtl" / "MagnitudeSquared.sv"
    test_dir = project_root / "verification" / "cocotb"

    runner = get_runner("icarus")

    runner.build(
        sources=[rtl_file],
        hdl_toplevel="MagnitudeSquared",
        timescale=("1ns", "1ps"),
        always=True,
    )

    runner.test(
        hdl_toplevel="MagnitudeSquared",
        test_module="MagnitudeSquaredTest",
        test_dir=test_dir,
    )


if __name__ == "__main__":
    run_test()