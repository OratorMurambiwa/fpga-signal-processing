// Test the AXI4-Lite control register.

`timescale 1ns / 1ps

module AxiLiteControlTestbench;

    logic clk;
    logic reset;

    logic [3:0]  s_axi_awaddr;
    logic        s_axi_awvalid;
    logic        s_axi_awready;

    logic [31:0] s_axi_wdata;
    logic        s_axi_wvalid;
    logic        s_axi_wready;

    logic [1:0]  s_axi_bresp;
    logic        s_axi_bvalid;
    logic        s_axi_bready;

    logic [3:0]  s_axi_araddr;
    logic        s_axi_arvalid;
    logic        s_axi_arready;

    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;

    logic [31:0] threshold;

    AxiLiteControl dut (
        .clk(clk),
        .reset(reset),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),

        .threshold(threshold)
    );

    // 100 MHz clock.
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        reset = 1'b1;

        s_axi_awaddr = 4'd0;
        s_axi_awvalid = 1'b0;

        s_axi_wdata = 32'd0;
        s_axi_wvalid = 1'b0;

        s_axi_bready = 1'b1;

        s_axi_araddr = 4'd0;
        s_axi_arvalid = 1'b0;

        s_axi_rready = 1'b1;

        repeat (3) @(posedge clk);

        @(negedge clk);
        reset = 1'b0;

        // Write 5000 to address 0x0.
        write_register(
            4'h0,
            32'd5000
        );

        if (threshold == 32'd5000) begin
            $display(
                "PASS: Threshold register stored 5000."
            );
        end
        else begin
            $display(
                "FAIL: Threshold register = %0d",
                threshold
            );
        end

        // Read the threshold back.
        read_register(4'h0);

        if (s_axi_rdata == 32'd5000) begin
            $display(
                "PASS: AXI4-Lite read returned 5000."
            );
        end
        else begin
            $display(
                "FAIL: AXI4-Lite read returned %0d",
                s_axi_rdata
            );
        end

        $finish;
    end

    task write_register(
        input logic [3:0]  address,
        input logic [31:0] data
    );
        begin
            @(negedge clk);

            s_axi_awaddr = address;
            s_axi_awvalid = 1'b1;

            s_axi_wdata = data;
            s_axi_wvalid = 1'b1;

            do begin
                @(posedge clk);
            end
            while (!(s_axi_awready && s_axi_wready));

            @(negedge clk);

            s_axi_awvalid = 1'b0;
            s_axi_wvalid = 1'b0;

            wait (s_axi_bvalid == 1'b1);

            @(posedge clk);
        end
    endtask

    task read_register(
        input logic [3:0] address
    );
        begin
            @(negedge clk);

            s_axi_araddr = address;
            s_axi_arvalid = 1'b1;

            do begin
                @(posedge clk);
            end
            while (!s_axi_arready);

            @(negedge clk);

            s_axi_arvalid = 1'b0;

            wait (s_axi_rvalid == 1'b1);

            @(negedge clk);
        end
    endtask

endmodule
