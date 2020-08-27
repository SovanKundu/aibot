package axi_bfm_pkg;

// TODO: these constants should be picked up from the axi_pkg
const bit [1:0] BURST_FIXED   = 2'b00;
const bit [1:0] BURST_INCR    = 2'b01;
const bit [1:0] BURST_WRAP    = 2'b10;

const bit [1:0] RESP_OKAY     = 2'b00;
const bit [1:0] RESP_EXOKAY   = 2'b01;
const bit [1:0] RESP_SLVERR   = 2'b10;
const bit [1:0] RESP_DECERR   = 2'b11;

const bit [0:0] ACCESS_NORMAL = 1'b0;
const bit [0:0] ACCESS_EXCLUSIVE = 1'b1;

class AxiLiteMaster #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 32);
    
    localparam DBW = DWIDTH/8;
    virtual global_if g;
    virtual axilite_if #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) axi;
    
    function new(virtual global_if g, virtual axilite_if #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) axi);
        this.g = g;
        this.axi = axi;
        axi.arvalid = 1'b0;
        axi.araddr  = '0;
        axi.rready  = 1'b0;
        axi.awvalid = 1'b0;
        axi.awaddr  = '0;
        axi.wvalid  = 1'b0;
        axi.wdata   = '0;
        axi.wstrb   = '0;
        axi.bready  = 1'b0;
    endfunction
    
    task ARTransaction(input [AWIDTH-1:0] addr);
        axi.arvalid = 1'b1;
        axi.araddr  = addr;
        @(posedge g.clk);
        while (!axi.arready) @(posedge g.clk);
        axi.arvalid = 1'b0;
    endtask
    
    task RTransaction(output [DWIDTH-1:0] data, output [2:0] resp);
        axi.rready = 1'b1;
        @(posedge g.clk);
        while(!axi.rvalid) @(posedge g.clk);
        data = axi.rdata;
        resp = axi.rresp;
        axi.rready = 1'b0;
    endtask
    
    task AWTransaction(input [AWIDTH-1:0] addr);
        axi.awvalid = 1'b1;
        axi.awaddr  = addr;
        @(posedge g.clk);
        while (!axi.awready) @(posedge g.clk);
        axi.awvalid = 1'b0;
    endtask
    
    task WTransaction(input [DWIDTH-1:0] data, input [DWIDTH/8-1:0] strb);
        axi.wvalid = 1'b1;
        axi.wdata  = data;
        axi.wstrb  = strb;
        @(posedge g.clk);
        while (!axi.wready) @(posedge g.clk);
        axi.wvalid = 1'b0;
    endtask
    
    task BTransaction(output [1:0] resp);
        axi.bready = 1'b1;
        @(posedge g.clk);
        while(!axi.bvalid) @(posedge g.clk);
        resp = axi.bresp;
        axi.bready = 1'b0;
    endtask
    
    task Read(input [AWIDTH-1:0] addr, output [DWIDTH-1:0] data, output [1:0] resp);
        ARTransaction(addr);
        RTransaction(data, resp);
    endtask
    
    task Write(input [AWIDTH-1:0] addr, input [DWIDTH-1:0] data, input [DWIDTH/8-1:0] strb, output [1:0] resp);
        fork 
            AWTransaction(addr);
            WTransaction(data, strb);
        join
        BTransaction(resp);
    endtask
    
    task ReadBytes(input [AWIDTH-1:0] addr, input int len, output byte data[], output [1:0] resp);
        int firstByteOffset, numWords, i;
        logic [AWIDTH-1:0] firstAlignedAddr, lastAlignedAddr, alignedAddr;
        logic [DWIDTH-1:0] alignedData;
        
        firstByteOffset = addr & (DBW-1);
        firstAlignedAddr = addr & ~(DBW-1);
        lastAlignedAddr  = (addr + len - 1) & ~(DBW-1);
        numWords = (lastAlignedAddr - firstAlignedAddr)/DBW + 1;
        data = new[len];
        i = 0;
        
        // Read first word
        alignedAddr = firstAlignedAddr;
        Read(alignedAddr, alignedData, resp);
        for (int j=firstByteOffset; j<DBW; i++, j++) begin
            if (i<len)
                data[i] = alignedData[j*8+:8];
            else
                break;
        end
        for(int w=1;w<numWords;w++) begin
            alignedAddr += DBW;
            Read(alignedAddr, alignedData, resp);
            for (int j=0; j<DBW; i++, j++) begin
                if (i<len)
                    data[i] = alignedData[j*8+:8];
                else
                    break;
            end
        end
        return;
    endtask
   
    task WriteBytes(input [AWIDTH-1:0] addr, input byte data[], output [1:0] resp);
        int len, numWords, firstByteOffset, lastByteOffset;
        logic [AWIDTH-1:0]  firstAlignedAddr, lastAlignedAddr, alignedAddr;
        logic [DWIDTH-1:0]  alignedData;
        bit [DBW-1:0] strb;
        
        len = $size(data);
        firstByteOffset = addr & (DBW-1); 
        lastByteOffset  = firstByteOffset + len - 1;
        firstAlignedAddr = addr & ~(DBW-1);
        lastAlignedAddr = (addr + len - 1) & ~(DBW-1);
        numWords = (lastAlignedAddr - firstAlignedAddr)/DBW + 1;
        
        alignedAddr = firstAlignedAddr;
        for(int i=0; i<numWords; i++) begin
            for(int j=0; j<DBW; j++) begin
                int index;
                index = DBW*i+j;
                alignedData[8*j +: 8] = (index < firstByteOffset) ? 8'h00 
                    : (index > lastByteOffset) ? 8'h00
                    : data[index-firstByteOffset];
                strb[j] = (index < firstByteOffset) ? 1'b0
                    : (index > lastByteOffset) ? 1'b0
                    : 1'b1;
            end
            Write(alignedAddr, alignedData, strb, resp);
            alignedAddr += DBW;
        end
    endtask
    
endclass


class AxiMaster #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 32);
    
    localparam DBW = DWIDTH/8;
    
    virtual global_if g;
    virtual axi_if  #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) axi;
    
    function new(virtual global_if g, virtual axi_if #(.AWIDTH(AWIDTH), .DWIDTH(DWIDTH)) axi);
        this.g = g;
        this.axi = axi;
        axi.arvalid = '0;
        axi.araddr  = '0;
        axi.arid    = '0;
        axi.arlen   = '0;
        axi.arsize  = '0;
        axi.arburst = '0;
        axi.arlock  = '0;
        axi.arcache = '0;
        axi.arprot  = '0;
        axi.rready  = '0;
        axi.awvalid = '0;
        axi.awaddr  = '0;
        axi.awid    = '0;
        axi.awlen   = '0;
        axi.awsize  = '0;
        axi.awburst = '0;
        axi.awlock  = '0;
        axi.awcache = '0;
        axi.awprot  = '0;
        axi.wvalid  = '0;
        axi.wdata   = '0;
        axi.wstrb   = '0;
        axi.wlast   = '0;
        axi.bready  = '0;
    endfunction
    
    task ARTransaction(input [AWIDTH-1:0] addr, len);
        axi.arvalid = 1'b1;
        axi.araddr  = addr;
        axi.arlen   = len;
        axi.arsize  = DWIDTH/8-1;
        axi.arburst = BURST_INCR;
        axi.arlock  = ACCESS_NORMAL;
        axi.arcache = 4'h0;
        axi.arprot  = 3'b000;
        @(posedge g.clk);
        while (!axi.arready) @(posedge g.clk);
        axi.arvalid = 1'b0;
    endtask

    task AWTransaction(input [AWIDTH-1:0] addr, len);
        axi.awvalid = 1'b1;
        axi.awaddr  = addr;
        axi.awlen   = len;
        axi.awsize  = DWIDTH/8-1;
        axi.awburst = BURST_INCR;
        axi.awlock  = ACCESS_NORMAL;
        axi.awcache = 4'h0;
        axi.awprot  = 3'b000;        
        @(posedge g.clk);
        while (!axi.awready) @(posedge g.clk);
        axi.awvalid = 1'b0;
    endtask

    task RTransaction(input int len, output [DWIDTH-1:0] data[], output [2:0] resp);
        data = new[DBW*256];
        for (int i=0; i<len; i++) begin
            axi.rready = 1'b1;
            @(posedge g.clk);
            while(!axi.rvalid) @(posedge g.clk);
            data[i] = axi.rdata;
            resp = axi.rresp;
        end
        axi.rready = 1'b0;
    endtask
        
    task WTransaction(input [DWIDTH-1:0] data[], input [DBW-1:0] strb[]);
        int len = $size(data);
        for (int i=0; i<len; i++) begin
            axi.wvalid = 1'b1;
            axi.wdata  = data[i];
            axi.wstrb  = strb[i];
            axi.wlast  = (i == len-1);
            @(posedge g.clk);
            while (!axi.wready) @(posedge g.clk);
        end
        axi.wvalid = 1'b0;
    endtask

    task BTransaction(output [1:0] resp);
        axi.bready = 1'b1;
        @(posedge g.clk);
        while(!axi.bvalid) @(posedge g.clk);
        resp = axi.bresp;
        axi.bready = 1'b0;
    endtask
    
    task Read(input [AWIDTH-1:0] addr, output [DWIDTH-1:0] data, output [1:0] resp);
        logic [AWIDTH-1:0] wAddr;
        logic [DWIDTH-1:0] wData[];
        
        wAddr = addr & ~(DBW-1);
        ARTransaction(wAddr, 0);
        RTransaction(1, wData, resp);
        data = wData[0];
    endtask

    task Write(input [AWIDTH-1:0] addr, input [DWIDTH-1:0] data, input [DBW-1:0] strb, output [1:0] resp);
        logic [AWIDTH-1:0]  wAddr;
        logic [DWIDTH-1:0]  wData[];
        logic [DBW-1:0]     wStrb[];
        byte wdata[];
        
        wAddr = addr & ~(DBW-1);
        wData = new[1];
        wStrb = new[1];
        wData[0] = data;
        wStrb[0] = strb;
        fork 
            AWTransaction(wAddr, 0);
            WTransaction(wData, wStrb);
        join
        BTransaction(resp);
    endtask
    
    task ReadBurst(input [AWIDTH-1:0] addr, input int len, output byte data[], output [1:0] resp);
        int firstByteOffset;
        int lastByteOffset;
        int burstLength;
        logic [AWIDTH-1:0]  alignedAddr;
        logic [DWIDTH-1:0]  alignedData[];
        
        firstByteOffset = addr & (DBW-1); 
        lastByteOffset  = firstByteOffset + len - 1;
        alignedAddr     = addr & ~(DBW-1);
        burstLength     = (lastByteOffset + DBW) / DBW;
        
        if (burstLength > 256) begin
            $error("Burst Length is more than 256");
            return;
        end
        
        ARTransaction(alignedAddr, burstLength-1);
        RTransaction(burstLength, alignedData, resp);
        data = new[len];
        for (int i=0; i<len; i++) begin
            int index;
            int offset;
            index   = (i + firstByteOffset) / DBW;
            offset  = (i + firstByteOffset) % DBW;
            data[i] = alignedData[index][offset*8 +: 8];
        end
        alignedData.delete();  
    endtask
   
    task WriteBurst(input [AWIDTH-1:0] addr, input byte data[], output [1:0] resp);
        int firstByteOffset;
        int lastByteOffset;
        int dataLength;
        int burstLength;
        logic [AWIDTH-1:0]  alignedAddr;
        logic [DWIDTH-1:0]  alignedData[];
        logic [DBW-1:0]     strb[];
        
        
        dataLength      = $size(data);
        firstByteOffset = addr & (DBW-1); 
        lastByteOffset  = firstByteOffset + dataLength - 1;
        alignedAddr     = addr & ~(DBW-1);
        burstLength     = (lastByteOffset + DBW) / DBW;
        
        if (burstLength > 256) begin
            $error("Burst Length is more than 256");
            return;
        end
        
        alignedData = new[burstLength];
        strb = new[burstLength];
        for(int i=0; i<burstLength; i++) begin
            for(int j=0; j<DBW; j++) begin
                int index;
                index = DBW*i+j;
                alignedData[i][8*j +: 8] = (index < firstByteOffset) ? 8'h00 
                    : (index > lastByteOffset) ? 8'h00
                    : data[index-firstByteOffset];
                strb[i][j] = (index < firstByteOffset) ? 1'b0
                    : (index > lastByteOffset) ? 1'b0
                    : 1'b1;
            end
        end
        fork
            AWTransaction(alignedAddr, burstLength-1);
            WTransaction(alignedData, strb);
        join
        BTransaction(resp);
    endtask
        
endclass

class AxiSlave #(
    parameter DW = 32,                  // Data Width
    parameter AW = 32,                  // Address Width
    parameter MS = 4096,                // Memory Size (bytes)
    parameter [AW-1:0] BaseAddr = '0    // memory Base Address
);
    virtual global_if g;
    virtual axi_if  #(.AWIDTH(AW), .DWIDTH(DW)) axi;
    byte mem[MS];

    function new(virtual global_if g, virtual axi_if #(.DWIDTH(DW), .AWIDTH(AW)) axi);
        this.g = g;
        this.axi = axi;
        axi.arready = '0;
        axi.rvalid  = '0;
        axi.rid     = '0;
        axi.rdata   = '0;
        axi.rresp   = '0;
        axi.rlast   = '0;
        axi.awready = '0;
        axi.wready  = '0;
        axi.bvalid  = '0;
        axi.bid     = '0;
        axi.bresp   = '0;
    endfunction

    task ARTransaction(output bit [AW-1:0] addr, output bit [7:0] len);
        axi.arready = 1'b1;
        @(posedge g.clk);
        while(!(axi.arvalid===1'b1)) @(posedge g.clk);
        addr = axi.araddr;
        len = axi.arlen;
        axi.arready = 1'b0;
    endtask

    task AWTransaction(output bit [AW-1:0] addr, output bit [7:0] len);
        axi.awready = 1'b1;
        @(posedge g.clk);
        while(!(axi.awvalid===1'b1)) @(posedge g.clk);
        addr = axi.awaddr;
        len = axi.awlen;
        axi.awready = 1'b0;
    endtask

    task RTransaction(input bit [DW-1:0] data[256], input bit [7:0] len, input bit [1:0] resp);
        axi.rvalid = 1'b1;
        axi.rresp = resp;
        for(int i=0; i<=len; i++) begin
            axi.rdata = data[i];
            axi.rlast = (i==len);
            @(posedge g.clk);
            while(!(axi.rready===1'b1)) @(posedge g.clk);
        end
        axi.rvalid = 1'b0;
    endtask

    task WTransaction(output bit [DW-1:0] data[256], output bit [DW/8-1:0] strb[256]);
        int i = 0;
        axi.wready = 1'b1;
        @(posedge g.clk);
        while(1) begin
            while(!(axi.wvalid===1'b1)) @(posedge g.clk);
            data[i] = axi.wdata;
            strb[i] = axi.wstrb;
            i+=1;
            if (axi.wlast === 1'b1)
                break;
            @(posedge g.clk);
        end
        axi.wready = 1'b0;
    endtask

    task BTransaction(input bit [1:0] resp);
        axi.bvalid = 1'b1;
        axi.bresp = resp;
        @(posedge g.clk);
        while(!(axi.bready===1'b1)) @(posedge g.clk);
        axi.bvalid = 1'b0;
    endtask

    task ReadLoop();
        bit [AW-1:0] addr;
        bit [7:0] len;
        bit [DW-1:0] data[256];
        byte buffer[4096];
        bit [1:0] resp;
        forever begin
            ARTransaction(addr, len);
            resp = Read(addr, (len+1) * DW/8, buffer);
            if (resp == RESP_OKAY) begin
                for (int i=0; i<=len; i++)
                    for (int j=0; j<DW/8; j++)
                        data[i][8*j+:8] = buffer[i*DW/8+j];
            end
            else begin
                len = 0;
            end
            RTransaction(data, len, resp);
        end
    endtask

    task WriteLoop();
        bit [AW-1:0] addr;
        bit [7:0] len;
        bit [DW-1:0] data[256];
        bit [DW/8-1:0] strb[256];
        byte buffer[4096];
        bit [1:0] resp;
        forever begin
            fork
                AWTransaction(addr, len);
                WTransaction(data, strb);
            join
            for (int i=0; i<=len; i++)
                for (int j=0; j<DW/8; j++)
                    buffer[i*DW/8+j] = data[i][8*j+:8];
            resp = Write(addr, (len+1) * DW/8, buffer); // TODO: length and address should be determined with strb
            BTransaction(resp);
        end
    endtask

    task  Run;
        fork
            ReadLoop();
            WriteLoop();
        join
    endtask

    virtual function bit [1:0] Read(input bit [AW-1:0] addr, input int len, output byte data[4096]);
    endfunction

    virtual function bit [1:0] Write(input bit [AW-1:0] addr, input int len, input byte data[4096]);
    endfunction
endclass

endpackage
