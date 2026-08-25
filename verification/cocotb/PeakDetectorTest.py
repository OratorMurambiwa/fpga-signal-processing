import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


async def reset_dut(dut):
    """Reset the peak detector."""

    dut.reset.value = 1
    dut.input_valid.value = 0
    dut.magnitude_in.value = 0
    dut.bin_index.value = 0
    dut.frame_start.value = 0
    dut.frame_end.value = 0
    dut.threshold.value = 0

    await Timer(20, unit="ns")

    dut.reset.value = 0
    await RisingEdge(dut.clk)
    await Timer(1, unit="ps")


async def send_sample(
    dut,
    magnitude,
    bin_index,
    frame_start=0,
    frame_end=0,
):
    """Send one magnitude sample into the detector."""

    dut.input_valid.value = 1
    dut.magnitude_in.value = magnitude
    dut.bin_index.value = bin_index
    dut.frame_start.value = frame_start
    dut.frame_end.value = frame_end

    await RisingEdge(dut.clk)
    await Timer(1, unit="ps")

    dut.input_valid.value = 0
    dut.frame_start.value = 0
    dut.frame_end.value = 0


@cocotb.test()
async def test_detects_largest_peak(dut):
    """Check that the largest bin in a frame is reported."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    dut.threshold.value = 0

    await send_sample(dut, 100, 0, frame_start=1)
    await send_sample(dut, 400, 1)
    await send_sample(dut, 900, 2)
    await send_sample(dut, 300, 3, frame_end=1)

    assert dut.peak_valid.value == 1
    assert dut.peak_bin.value.to_unsigned() == 2
    assert dut.peak_magnitude.value.to_unsigned() == 900


@cocotb.test()
async def test_peak_above_threshold(dut):
    """Check that a peak above the threshold is accepted."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    dut.threshold.value = 500

    await send_sample(dut, 200, 0, frame_start=1)
    await send_sample(dut, 700, 1)
    await send_sample(dut, 300, 2, frame_end=1)

    assert dut.peak_valid.value == 1
    assert dut.peak_bin.value.to_unsigned() == 1
    assert dut.peak_magnitude.value.to_unsigned() == 700


@cocotb.test()
async def test_peak_below_threshold(dut):
    """Check that a peak below the threshold is rejected."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    dut.threshold.value = 1000

    await send_sample(dut, 200, 0, frame_start=1)
    await send_sample(dut, 700, 1)
    await send_sample(dut, 300, 2, frame_end=1)

    assert dut.peak_valid.value == 0


@cocotb.test()
async def test_multiple_frames(dut):
    """Check that a new frame does not reuse the old peak."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    dut.threshold.value = 0

    await send_sample(dut, 200, 0, frame_start=1)
    await send_sample(dut, 900, 1, frame_end=1)

    assert dut.peak_valid.value == 1
    assert dut.peak_bin.value.to_unsigned() == 1
    assert dut.peak_magnitude.value.to_unsigned() == 900

    await send_sample(dut, 80, 0, frame_start=1)
    await send_sample(dut, 120, 1, frame_end=1)

    assert dut.peak_valid.value == 1
    assert dut.peak_bin.value.to_unsigned() == 1
    assert dut.peak_magnitude.value.to_unsigned() == 120