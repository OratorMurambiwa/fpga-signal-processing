// AXI4-Lite control register.

module AxiLiteControl (
    input  logic        clk,
    input  logic        reset,

    // Write address channel.
    input  logic [3:0]  s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    // Write data channel.
    input  logic [31:0] s_axi_wdata,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    // Write response channel.
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    // Read address channel.
    input  logic [3:0]  s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // Read data channel.
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // Configuration output.
    output logic [31:0] threshold
);

    // Accept a write when both address and data are valid.
    assign s_axi_awready =
        !s_axi_bvalid
        && s_axi_awvalid
        && s_axi_wvalid;

    assign s_axi_wready =
        !s_axi_bvalid
        && s_axi_awvalid
        && s_axi_wvalid;

    // Accept a read when no previous read is waiting.
    assign s_axi_arready = !s_axi_rvalid;

    always_ff @(posedge clk) begin
        if (reset) begin
            threshold <= 32'd0;

            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;

            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'd0;
            s_axi_rresp <= 2'b00;
        end
        else begin
            // AXI4-Lite write.
            if (
                s_axi_awvalid
                && s_axi_awready
                && s_axi_wvalid
                && s_axi_wready
            ) begin

                // Address 0x0 stores the threshold.
                if (s_axi_awaddr == 4'h0) begin
                    threshold <= s_axi_wdata;
                end

                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00;
            end
            else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            // AXI4-Lite read.
            if (s_axi_arvalid && s_axi_arready) begin

                if (s_axi_araddr == 4'h0) begin
                    s_axi_rdata <= threshold;
                end
                else begin
                    s_axi_rdata <= 32'd0;
                end

                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00;
            end
            else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
