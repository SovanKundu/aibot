package axi_pkg;
const bit [1:0] BURST_FIXED   = 2'b00;
const bit [1:0] BURST_INCR    = 2'b01;
const bit [1:0] BURST_WRAP    = 2'b10;

const bit [1:0] RESP_OKAY     = 2'b00;
const bit [1:0] RESP_EXOKAY   = 2'b01;
const bit [1:0] RESP_SLVERR   = 2'b10;
const bit [1:0] RESP_DECERR   = 2'b11;

const bit [0:0] ACCESS_NORMAL = 1'b0;
const bit [0:0] ACCESS_EXCLUSIVE = 1'b1;

endpackage
