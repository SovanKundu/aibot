module MotorController (
    input   clk,
    input   rst,

    input           Dir,
    input [31:0]    HiCount,
    input [31:0]    LoCount,
    output logic    M_A,
    output logic    M_B,
    input           S_A,
    input           S_B,
    output logic [31:0]   Count
);

    enum {LOS, HIS} rState, sState;
    logic [31:0] rCount, sCount;

    always @(posedge clk) begin
        rState <= sState;
        rCount <= sCount;
    end

    always @* begin
        sState = rState;
        sCount = rCount;
        if ((HiCount == '0) && (LoCount == '0)) begin
            sState = LOS;
            sCount = '0;
        end
        else if (HiCount == '0) begin
            sState = LOS;
            sCount = '0;
        end
        else if (LoCount == '0) begin
            sState = HIS;
            sCount = '0;
        end
        else begin
            sCount = rCount + 1;
            case (rState)
            LOS: if (rCount == LoCount) begin
                sState = HIS;
                sCount = 1;
            end
            HIS: if (rCount == HiCount) begin
                sState = LOS;
                sCount = 1;
            end
            endcase
        end
    end

    always @(posedge clk) begin
        M_A <= Dir ? (rState == HIS) : 1'b0;
        M_B <= Dir ? 1'b0 : (rState == HIS);
    end

    logic SA, SB;
    logic rSA, rSB;

    always @(posedge clk) begin
        rSA <= SA;
        rSB <= SB;
    end

    logic CountEn, CountDir;
    assign CountEn = SA ^ rSA ^ SB ^ rSB;
    assign CountDir = SA ^ rSB;

    always @(posedge clk) begin
        if (rst)
            Count <= '0;
        else if (CountEn)
            Count <= CountDir ? Count + 1 : Count - 1;
    end

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(4),
        .INIT_SYNC_FF(0),
        .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(0),
        .WIDTH(2)
    )
    synchronizer (
        .dest_out   ({SA, SB}),
        .dest_clk   (clk),
        .src_clk    (1'b0),
        .src_in     ({S_A, S_B})
    );


endmodule
