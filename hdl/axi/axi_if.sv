interface axilite_if #(
    parameter DWIDTH = 32,
    parameter AWIDTH = 32
);
    logic                   arvalid;
    logic                   arready;
    logic [AWIDTH-1:0]      araddr;
    logic                   rvalid;
    logic                   rready;
    logic [DWIDTH-1:0]      rdata;
    logic [1:0]             rresp;
    logic                   awvalid;
    logic                   awready;
    logic [AWIDTH-1:0]      awaddr;
    logic                   wvalid;
    logic                   wready;
    logic [DWIDTH-1:0]      wdata;
    logic [DWIDTH/8-1:0]    wstrb;
    logic                   bvalid;
    logic                   bready;
    logic [1:0]             bresp;
    
    modport master(
        output arvalid,
        input  arready,
        output araddr,
        input  rvalid,
        output rready,
        input  rdata,
        input  rresp,
        output awvalid,
        input  awready,
        output awaddr,
        output wvalid,
        input  wready,
        output wdata,
        output wstrb,
        input  bvalid,
        output bready,
        input  bresp);
        
    modport slave(
        input  arvalid,
        output arready,
        input  araddr,
        output rvalid,
        input  rready,
        output rdata,
        output rresp,
        input  awvalid,
        output awready,
        input  awaddr,
        input  wvalid,
        output wready,
        input  wdata,
        input  wstrb,
        output bvalid,
        input  bready,
        output bresp);
    
endinterface


interface axi_if #(
    parameter DWIDTH  = 32,
    parameter AWIDTH  = 32,
    parameter IDWIDTH = 4
);
    logic                   arvalid;
    logic                   arready;
    logic [AWIDTH-1:0]      araddr;
    logic [IDWIDTH-1:0]     arid;
    logic [7:0]             arlen;
    logic [2:0]             arsize;
    logic [1:0]             arburst;
    logic                   arlock;
    logic [3:0]             arcache;
    logic [2:0]             arprot;
    logic                   rvalid;
    logic                   rready;
    logic [IDWIDTH-1:0]     rid;
    logic [DWIDTH-1:0]      rdata;
    logic [1:0]             rresp;
    logic                   rlast;
    logic                   awvalid;
    logic                   awready;
    logic [AWIDTH-1:0]      awaddr;
    logic [IDWIDTH-1:0]     awid;
    logic [7:0]             awlen;
    logic [2:0]             awsize;
    logic [1:0]             awburst;
    logic                   awlock;
    logic [3:0]             awcache;
    logic [2:0]             awprot;
    logic                   wvalid;
    logic                   wready;
    logic [DWIDTH-1:0]      wdata;
    logic [DWIDTH/8-1:0]    wstrb;
    logic                   wlast;
    logic                   bvalid;
    logic                   bready;
    logic [IDWIDTH-1:0]     bid;
    logic [1:0]             bresp;
    
    modport master(
        output arvalid,
        input  arready,
        output araddr,
        output arid,
        output arlen,
        output arsize,
        output arburst,
        output arlock,
        output arcache,
        output arprot,
        input  rvalid,
        output rready,
        input  rid,
        input  rdata,
        input  rresp,
        input  rlast,
        output awvalid,
        input  awready,
        output awaddr,
        output awid,
        output awlen,
        output awsize,
        output awburst,
        output awlock,
        output awcache,
        output awprot,
        output wvalid,
        input  wready,
        output wdata,
        output wstrb,
        output wlast,
        input  bvalid,
        output bready,
        input  bid,
        input  bresp);
        
    modport slave(
        input  arvalid,
        output arready,
        input  araddr,
        input  arid,
        input  arlen,
        input  arsize,
        input  arburst,
        input  arlock,
        input  arcache,
        input  arprot,
        output rvalid,
        input  rready,
        output rid,
        output rdata,
        output rresp,
        output rlast,
        input  awvalid,
        output awready,
        input  awaddr,
        input  awid,
        input  awlen,
        input  awsize,
        input  awburst,
        input  awlock,
        input  awcache,
        input  awprot,
        input  wvalid,
        output wready,
        input  wdata,
        input  wstrb,
        input  wlast,
        output bvalid,
        input  bready,
        output bid,
        output bresp);
    
endinterface
    
