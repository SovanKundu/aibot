module axilite_bram_ctlr #(
    parameter MDL2 = 12,    // Memory Depth Log 2
    parameter BWL2 = 3,     // Byte Width Log 2
    parameter RL   = 2,     // Read Latency
    parameter WFL2 = 0      // Width Factor Log 2
)(
    input                           clk,
    input                           rst,
    axilite_if.slave                axil,
    output                          bram_en,
    output [2**(BWL2+WFL2)-1:0]     bram_we,
    output [MDL2-1:0]               bram_addr,
    output [8*2**(BWL2+WFL2)-1:0]   bram_wrdata,
    input  [8*2**(BWL2+WFL2)-1:0]   bram_rddata
);

    enum {AXI_IDLE, AXI_READ_WAIT, AXI_READ_RESP, AXI_WRITE, AXI_WRITE_RESP} rAxiState, sAxiState;    
    logic [3:0]         rCount, sCount;
    logic [MDL2-1:0]    rAddr, sAddr;
    logic [8*2**BWL2-1:0] rWrData, sWrData, rRdData, sRdData;
    logic               rEn, sEn;
    logic [2**BWL2-1:0] rWe, sWe;
    logic               rARReady, sARReady;
    logic [WFL2-1:0]    rWidthShift, sWidthShift;

    always @(posedge clk) begin
        if (rst)
            rAxiState <= AXI_IDLE;
        else 
            rAxiState <= sAxiState;
    end
    
    always @(posedge clk) begin
        rAddr <= sAddr;
        rWrData <= sWrData;
        rRdData <= sRdData;
        rEn <= sEn;
        rWe <= sWe;
        rCount <= sCount;
        rARReady <= sARReady;
        rWidthShift <= sWidthShift;
    end
    
    always @* begin
        sAxiState = rAxiState;
        sAddr = rAddr;
        sWrData = rWrData;
        sRdData = rRdData;
        sEn = 1'b0;
        sWe = '0;
        sCount = rCount;
        sARReady = 1'b0;
        sWidthShift = rWidthShift;
        case(rAxiState)
            AXI_IDLE: begin
                if(axil.awvalid && axil.wvalid) begin
                    sAxiState = AXI_WRITE;
                    sWidthShift = (WFL2==0) ? '0 : axil.awaddr[BWL2 +: WFL2];
                    sAddr = axil.awaddr[(BWL2+WFL2) +: MDL2];
                    sWrData = axil.wdata;
                    sEn = 1'b1;
                    sWe = axil.wstrb;
                end
                else if(axil.arvalid) begin
                    sAxiState = AXI_READ_WAIT;
                    sWidthShift = (WFL2==0) ? '0 : axil.araddr[BWL2 +: WFL2];
                    sAddr = axil.araddr[(BWL2+WFL2) +: MDL2];
                    sEn = 1'b1;
                    sCount = RL-1;
                    sARReady = 1'b1;
                end
            end
            AXI_READ_WAIT: begin
                if (rCount == 0) begin
                    sAxiState = AXI_READ_RESP;
                    sRdData = bram_rddata;
                end
                sCount = rCount - 1;
            end
            AXI_READ_RESP:
                if (axil.rready)
                    sAxiState = AXI_IDLE;
            AXI_WRITE:
                sAxiState = AXI_WRITE_RESP;
            AXI_WRITE_RESP:
                if (axil.bready)
                    sAxiState = AXI_IDLE;
        endcase
    end
    
    assign bram_en = rEn;
    assign bram_addr = rAddr;
    assign bram_we = (WFL2==0) ? rWe : (rWe << rWidthShift*2**BWL2);
    assign bram_wrdata = (WFL2==0) ? rWrData : (rWrData << rWidthShift*8*2**BWL2);
    
    assign axil.awready = (rAxiState == AXI_WRITE);
    assign axil.wready  = (rAxiState == AXI_WRITE);
    assign axil.bvalid  = (rAxiState == AXI_WRITE_RESP);
    assign axil.bresp   = 2'b00;
    assign axil.arready = rARReady;
    assign axil.rvalid  = (rAxiState == AXI_READ_RESP);
    assign axil.rdata   = (WFL2==0) ? bram_rddata : bram_rddata[rWidthShift*8*2**BWL2+:8*2**BWL2];
    assign axil.rresp   = 2'b00;
    
endmodule    
