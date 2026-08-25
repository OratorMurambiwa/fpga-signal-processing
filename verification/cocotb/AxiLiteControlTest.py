import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


async def reset_dut(dut):
    """Reset the AXI-Lite control module."""

    dut.reset.value = 1

    dut.s_axi_awaddr.value = 0
    dut.s_axi_awvalid.value = 0
    dut.s_axi_wdata.value = 0
    dut.s_axi_wvalid.value = 0
    dut.s_axi_bready.value = 0

    dut.s_axi_araddr.value = 0
    dut.s_axi_arvalid.value = 0
    dut.s_axi_rready.value = 0

    await Timer(20, unit="ns")

    dut.reset.value = 0
    await RisingEdge(dut.clk)


@cocotb.test()
async def test_normal_write_and_read(dut):
    """Write and read the threshold register."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    # Write 5000 to register address 0.
    dut.s_axi_awaddr.value = 0
    dut.s_axi_awvalid.value = 1
    dut.s_axi_wdata.value = 5000
    dut.s_axi_wvalid.value = 1
    dut.s_axi_bready.value = 1

    await RisingEdge(dut.clk)

    dut.s_axi_awvalid.value = 0
    dut.s_axi_wvalid.value = 0

    await RisingEdge(dut.clk)

    assert dut.threshold.value.to_unsigned() == 5000

    # Read register address 0.
    dut.s_axi_araddr.value = 0
    dut.s_axi_arvalid.value = 1
    dut.s_axi_rready.value = 1

    await RisingEdge(dut.clk)

    dut.s_axi_arvalid.value = 0

    await RisingEdge(dut.clk)

    assert dut.s_axi_rdata.value.to_unsigned() == 5000


@cocotb.test()
async def test_address_before_data(dut):
    """Send the write address before the write data."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    # Send the address first.
    dut.s_axi_awaddr.value = 0
    dut.s_axi_awvalid.value = 1

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # Send the data two cycles later.
    dut.s_axi_wdata.value = 7000
    dut.s_axi_wvalid.value = 1
    dut.s_axi_bready.value = 1

    await RisingEdge(dut.clk)

    dut.s_axi_awvalid.value = 0
    dut.s_axi_wvalid.value = 0

    await RisingEdge(dut.clk)

    assert dut.threshold.value.to_unsigned() == 7000


@cocotb.test()
async def test_data_before_address(dut):
    """Send the write data before the write address."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    # Send the data first.
    dut.s_axi_wdata.value = 9000
    dut.s_axi_wvalid.value = 1

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    # Send the address two cycles later.
    dut.s_axi_awaddr.value = 0
    dut.s_axi_awvalid.value = 1
    dut.s_axi_bready.value = 1

    await RisingEdge(dut.clk)

    dut.s_axi_awvalid.value = 0
    dut.s_axi_wvalid.value = 0

    await RisingEdge(dut.clk)

    assert dut.threshold.value.to_unsigned() == 9000


@cocotb.test()
async def test_reset_clears_threshold(dut):
    """Check that reset clears the threshold register."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    # Write a nonzero threshold.
    dut.s_axi_awaddr.value = 0
    dut.s_axi_awvalid.value = 1
    dut.s_axi_wdata.value = 12000
    dut.s_axi_wvalid.value = 1
    dut.s_axi_bready.value = 1

    await RisingEdge(dut.clk)

    dut.s_axi_awvalid.value = 0
    dut.s_axi_wvalid.value = 0

    await RisingEdge(dut.clk)

    assert dut.threshold.value.to_unsigned() == 12000

    # Reset the module again.
    dut.reset.value = 1
    await RisingEdge(dut.clk)

    dut.reset.value = 0
    await RisingEdge(dut.clk)

    assert dut.threshold.value.to_unsigned() == 0


@cocotb.test()
async def test_invalid_read_address(dut):
    """Check that an unused address returns zero."""

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    await reset_dut(dut)

    # Read from an unused register address.
    dut.s_axi_araddr.value = 4
    dut.s_axi_arvalid.value = 1
    dut.s_axi_rready.value = 1

    await RisingEdge(dut.clk)

    dut.s_axi_arvalid.value = 0

    await RisingEdge(dut.clk)

    assert dut.s_axi_rdata.value.to_unsigned() == 0