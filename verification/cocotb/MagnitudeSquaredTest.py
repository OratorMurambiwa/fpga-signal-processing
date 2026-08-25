import cocotb
from cocotb.triggers import Timer


async def check_magnitude(dut, real_value, imag_value, expected):
    """Apply one complex sample and check magnitude squared."""

    dut.real_in.value = real_value
    dut.imag_in.value = imag_value

    await Timer(1, unit="ns")

    assert dut.magnitude_squared.value.to_unsigned() == expected


@cocotb.test()
async def test_positive_values(dut):
    """Check normal positive inputs."""

    await check_magnitude(
        dut,
        real_value=3000,
        imag_value=1500,
        expected=11250000,
    )


@cocotb.test()
async def test_signed_values(dut):
    """Check signed real and imaginary inputs."""

    await check_magnitude(
        dut,
        real_value=-2000,
        imag_value=1000,
        expected=5000000,
    )


@cocotb.test()
async def test_zero_input(dut):
    """Check that zero input produces zero output."""

    await check_magnitude(
        dut,
        real_value=0,
        imag_value=0,
        expected=0,
    )


@cocotb.test()
async def test_extreme_negative_values(dut):
    """Check the largest negative 16-bit input values."""

    await check_magnitude(
        dut,
        real_value=-32768,
        imag_value=-32768,
        expected=2147483648,
    )