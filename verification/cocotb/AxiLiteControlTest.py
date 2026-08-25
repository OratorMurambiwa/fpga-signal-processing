import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


async def reset_dut(dut):
    """Reset the AXI-Lite control module."""

    dut.reset.value = 1

    # Clear the AXI-Lite inputs during reset.
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
    """Write and read the threshold register through AXI-Lite."""

    # Run a 100 MHz clock.
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

    # Check that the threshold register was updated.
    assert dut.threshold.value.integer == 5000

    # Read register address 0.
    dut.s_axi_araddr.value = 0
    dut.s_axi_arvalid.value = 1
    dut.s_axi_rready.value = 1

    await RisingEdge(dut.clk)

    dut.s_axi_arvalid.value = 0

    await RisingEdge(dut.clk)

    # Check that AXI-Lite returned the stored value.
    assert dut.s_axi_rdata.value.integer == 5000