import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


async def wait_clock(dut):
    """Wait for a clock edge and let RTL outputs settle."""

    await RisingEdge(dut.clk)
    await Timer(1, unit="ps")


async def reset_dut(dut):
    """Reset the FIR filter."""

    dut.reset.value = 1
    dut.input_valid.value = 0
    dut.input_data.value = 0
    dut.output_ready.value = 0

    await Timer(20, unit="ns")

    dut.reset.value = 0
    await wait_clock(dut)


@cocotb.test()
async def test_normal_filtering(dut):
    """Check FIR outputs with normal handshaking."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    dut.output_ready.value = 1

    samples = [1000, 2000, 3000]
    expected = [49, 199, 549]

    for sample, expected_output in zip(samples, expected):
        dut.input_data.value = sample
        dut.input_valid.value = 1

        while not dut.input_ready.value:
            await wait_clock(dut)

        await wait_clock(dut)

        dut.input_valid.value = 0

        assert dut.output_valid.value == 1
        assert dut.output_data.value.to_signed() == expected_output


@cocotb.test()
async def test_reset_behavior(dut):
    """Check that reset clears the output state."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    dut.output_ready.value = 1
    dut.input_data.value = 1000
    dut.input_valid.value = 1

    await wait_clock(dut)

    dut.input_valid.value = 0

    assert dut.output_valid.value == 1

    dut.reset.value = 1
    await wait_clock(dut)

    assert dut.output_valid.value == 0
    assert dut.output_data.value.to_signed() == 0

    dut.reset.value = 0
    await wait_clock(dut)


@cocotb.test()
async def test_backpressure_holds_output(dut):
    """Check that stalled output stays unchanged."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    dut.output_ready.value = 0

    dut.input_data.value = 1000
    dut.input_valid.value = 1

    await wait_clock(dut)

    dut.input_valid.value = 0

    held_output = dut.output_data.value.to_signed()

    assert dut.output_valid.value == 1

    # Hold the output while the receiver is not ready.
    for _ in range(3):
        await wait_clock(dut)

        assert dut.output_valid.value == 1
        assert dut.output_data.value.to_signed() == held_output


@cocotb.test()
async def test_resume_after_backpressure(dut):
    """Check that the FIR resumes after backpressure."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    dut.output_ready.value = 0

    dut.input_data.value = 1000
    dut.input_valid.value = 1

    await wait_clock(dut)

    dut.input_valid.value = 0

    assert dut.output_valid.value == 1
    assert dut.output_data.value.to_signed() == 49

    # Allow the first output to be consumed.
    dut.output_ready.value = 1
    await wait_clock(dut)

    assert dut.output_valid.value == 0

    # Send the next sample.
    dut.input_data.value = 2000
    dut.input_valid.value = 1

    await wait_clock(dut)

    dut.input_valid.value = 0

    assert dut.output_valid.value == 1
    assert dut.output_data.value.to_signed() == 199