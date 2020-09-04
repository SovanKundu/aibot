module DriveController (
    input   clk,
    input   rst,

    axilite_if.slave    axil,

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

    localparam AXI_ADDR_DECODE_BITS = 8;
    enum {AXI_IDLE, AXI_READ, AXI_WRITE, AXI_READ_RESP, AXI_WRITE_RESP} rAxiState, sAxiState;    
    logic [63:0] ReadData;

    logic fl_dir, fr_dir, bl_dir, br_dir;
    logic [31:0] fl_hi, fl_lo;
    logic [31:0] fr_hi, fr_lo;
    logic [31:0] bl_hi, bl_lo;
    logic [31:0] br_hi, br_lo;
    logic [31:0] fl_count, fr_count, bl_count, br_count;

    always @(posedge clk) begin
        if (rst)
            rAxiState <= AXI_IDLE;
        else
            rAxiState <= sAxiState;
    end
    
    always @* begin
        sAxiState = rAxiState;
        case(rAxiState)
            AXI_IDLE: 
                if(axil.awvalid && axil.wvalid)
                    sAxiState = AXI_WRITE;
                else if(axil.arvalid)
                    sAxiState = AXI_READ;
            AXI_READ:
                sAxiState = AXI_READ_RESP;
            AXI_WRITE:
                sAxiState = AXI_WRITE_RESP;
            AXI_READ_RESP:
                if (axil.rready)
                    sAxiState = AXI_IDLE;
            AXI_WRITE_RESP:
                if (axil.bready)
                    sAxiState = AXI_IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rAxiState == AXI_WRITE) begin
            case(axil.awaddr[AXI_ADDR_DECODE_BITS-1:3])
                0: begin
                    if (axil.wstrb[1])
                        {br_dir, bl_dir, fr_dir, fl_dir} <= axil.wdata[11:8];
                end
                4: begin
                    if (&axil.wstrb[3:0])
                        fl_lo <= axil.wdata[31:0];
                    if (&axil.wstrb[7:4])
                        fl_hi <= axil.wdata[63:32];
                end
                5: begin
                    if (&axil.wstrb[3:0])
                        fr_lo <= axil.wdata[31:0];
                    if (&axil.wstrb[7:4])
                        fr_hi <= axil.wdata[63:32];
                end
                6: begin
                    if (&axil.wstrb[3:0])
                        bl_lo <= axil.wdata[31:0];
                    if (&axil.wstrb[7:4])
                        bl_hi <= axil.wdata[63:32];
                end
                7: begin
                    if (&axil.wstrb[3:0])
                        br_lo <= axil.wdata[31:0];
                    if (&axil.wstrb[7:4])
                        br_hi <= axil.wdata[63:32];
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (rAxiState == AXI_READ) begin
            case (axil.araddr[AXI_ADDR_DECODE_BITS-1:3])
                0:  ReadData <= {'0, br_dir, bl_dir, fr_dir, fl_dir, 8'h0};
                4:  ReadData <= {fl_hi, fl_lo};
                5:  ReadData <= {fr_hi, fr_lo};
                6:  ReadData <= {bl_hi, bl_lo};
                7:  ReadData <= {br_hi, br_lo};
                8:  ReadData <= {'0, fl_count};
                9:  ReadData <= {'0, fr_count};
                10: ReadData <= {'0, bl_count};
                11: ReadData <= {'0, br_count};
                default: ReadData <= 64'h0;
            endcase
        end
    end

    assign axil.awready = (rAxiState == AXI_WRITE);
    assign axil.wready  = (rAxiState == AXI_WRITE);
    assign axil.bvalid  = (rAxiState == AXI_WRITE_RESP);
    assign axil.bresp   = 2'b00;
    assign axil.arready = (rAxiState == AXI_READ);
    assign axil.rvalid  = (rAxiState == AXI_READ_RESP);
    assign axil.rdata   = ReadData;
    assign axil.rresp   = 2'b00;

    MotorController flmc (
        .clk    (clk),
        .rst    (rst),

        .Dir    (fl_dir),
        .HiCount     (fl_hi),
        .LoCount     (fl_lo),
        .Count  (fl_count),

        .M_A    (MFL_A),
        .M_B    (MFL_B),
        .S_A    (SFL_A),
        .S_B    (SFL_B)
    );

    MotorController frmc (
        .clk    (clk),
        .rst    (rst),

        .Dir    (fr_dir),
        .HiCount     (fr_hi),
        .LoCount     (fr_lo),
        .Count  (fr_count),

        .M_A    (MFR_A),
        .M_B    (MFR_B),
        .S_A    (SFR_A),
        .S_B    (SFR_B)
    );

    MotorController blmc (
        .clk    (clk),
        .rst    (rst),

        .Dir    (bl_dir),
        .HiCount     (bl_hi),
        .LoCount     (bl_lo),
        .Count  (bl_count),

        .M_A    (MBL_A),
        .M_B    (MBL_B),
        .S_A    (SBL_A),
        .S_B    (SBL_B)
    );

    MotorController brmc (
        .clk    (clk),
        .rst    (rst),

        .Dir    (br_dir),
        .HiCount     (br_hi),
        .LoCount     (br_lo),
        .Count  (br_count),

        .M_A    (MBR_A),
        .M_B    (MBR_B),
        .S_A    (SBR_A),
        .S_B    (SBR_B)
    );

endmodule
