module ZyboZ7 (
    inout [14:0]DDR_addr,
    inout [2:0]DDR_ba,
    inout DDR_cas_n,
    inout DDR_ck_n,
    inout DDR_ck_p,
    inout DDR_cke,
    inout DDR_cs_n,
    inout [3:0]DDR_dm,
    inout [31:0]DDR_dq,
    inout [3:0]DDR_dqs_n,
    inout [3:0]DDR_dqs_p,
    inout DDR_odt,
    inout DDR_ras_n,
    inout DDR_reset_n,
    inout DDR_we_n,
    inout FIXED_IO_ddr_vrn,
    inout FIXED_IO_ddr_vrp,
    inout [53:0]FIXED_IO_mio,
    inout FIXED_IO_ps_clk,
    inout FIXED_IO_ps_porb,
    inout FIXED_IO_ps_srstb,

    output MFL_A,
    output MFL_B,
    input  SFL_A,
    input  SFL_B,

    output MFR_A,
    output MFR_B,
    input  SFR_A,
    input  SFR_B,

    output MBL_A,
    output MBL_B,
    input  SBL_A,
    input  SBL_B,

    output MBR_A,
    output MBR_B,
    input  SBR_A,
    input  SBR_B
);

    logic clk;
    logic rstn;

    axilite_if #(.DWIDTH(64), .AWIDTH(32)) axil_dc();

    PS ps (
        .DDR_addr           (DDR_addr),
        .DDR_ba             (DDR_ba),
        .DDR_cas_n          (DDR_cas_n),
        .DDR_ck_n           (DDR_ck_n),
        .DDR_ck_p           (DDR_ck_p),
        .DDR_cke            (DDR_cke),
        .DDR_cs_n           (DDR_cs_n),
        .DDR_dm             (DDR_dm),
        .DDR_dq             (DDR_dq),
        .DDR_dqs_n          (DDR_dqs_n),
        .DDR_dqs_p          (DDR_dqs_p),
        .DDR_odt            (DDR_odt),
        .DDR_ras_n          (DDR_ras_n),
        .DDR_reset_n        (DDR_reset_n),
        .DDR_we_n           (DDR_we_n),
        .FIXED_IO_ddr_vrn   (FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp   (FIXED_IO_ddr_vrp),
        .FIXED_IO_mio       (FIXED_IO_mio),
        .FIXED_IO_ps_clk    (FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb   (FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb  (FIXED_IO_ps_srstb),
        .axil_dc_araddr     (axil_dc.araddr),
        .axil_dc_arprot     (),
        .axil_dc_arready    (axil_dc.arready),
        .axil_dc_arvalid    (axil_dc.arvalid),
        .axil_dc_awaddr     (axil_dc.awaddr),
        .axil_dc_awprot     (),
        .axil_dc_awready    (axil_dc.awready),
        .axil_dc_awvalid    (axil_dc.awvalid),
        .axil_dc_bready     (axil_dc.bready),
        .axil_dc_bresp      (axil_dc.bresp),
        .axil_dc_bvalid     (axil_dc.bvalid),
        .axil_dc_rdata      (axil_dc.rdata),
        .axil_dc_rready     (axil_dc.rready),
        .axil_dc_rresp      (axil_dc.rresp),
        .axil_dc_rvalid     (axil_dc.rvalid),
        .axil_dc_wdata      (axil_dc.wdata),
        .axil_dc_wready     (axil_dc.wready),
        .axil_dc_wstrb      (axil_dc.wstrb),
        .axil_dc_wvalid     (axil_dc.wvalid),
        .axil_aclk          (clk),
        .axil_aresetn       (rstn)
    );

    DriveController dc(
        .clk    (clk),
        .rst    (!rstn),

        .axil   (axil_dc),

        .MFL_A  (MFL_A),
        .MFL_B  (MFL_B),
        .SFL_A  (SFL_A),
        .SFL_B  (SFL_B),
        .MFR_A  (MFR_A),
        .MFR_B  (MFR_B),
        .SFR_A  (SFR_A),
        .SFR_B  (SFR_B),

        .MBL_A  (MBL_A),
        .MBL_B  (MBL_B),
        .SBL_A  (SBL_A),
        .SBL_B  (SBL_B),
        .MBR_A  (MBR_A),
        .MBR_B  (MBR_B),
        .SBR_A  (SBR_A),
        .SBR_B  (SBR_B)

    );    
    
    logic [15:0] probe0;
    
    assign probe0 = {SBR_B, SBR_A, MBR_B, MBR_A, SBL_B, SBL_A, MBL_B, MBL_A, SFR_B, SFR_A, MFR_B, MFR_A, SFL_B, SFL_A, MFL_B, MFL_A};
    
    ila_0 ila_0 (
	   .clk(clk), // input wire clk
	   .probe0(probe0) // input wire [15:0] probe0
    );
         
endmodule
