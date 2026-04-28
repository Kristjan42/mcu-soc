package mcu_soc_pkg;

  /*
  localparam obi_pkg::obi_cfg_t ObiCfg = '{
    UseRReady:   1'b1,
    CombGnt:     1'b0,
    AddrWidth:   32,
    DataWidth:   32,
    IdWidth:     4,
    Integrity:   1'b0,
    BeFull:      1'b1,
    OptionalCfg: '0
  };
  */

  import obi_pkg::*;

  typedef struct packed {
    logic [AddrWidth-1:0]   addr;
    logic                          we;
    logic [DataWidth/8-1:0] be;
    logic [DataWidth-1:0]   wdata;
    logic [IdWidth-1:0]     aid;
    logic                          a_optional;
  } obi_a_chan_t;

  typedef struct packed {
    obi_a_chan_t a;
    logic            req;
    logic            rready;
  } obi_req_t;

  typedef struct packed {
    logic [DataWidth-1:0] rdata;
    logic [IdWidth-1:0]   rid;
    logic                        err;
    logic                        r_optional;
  } obi_r_chan_t;

  typedef struct packed {
    obi_r_chan_t     r;
    logic            gnt;
    logic            rvalid;
  } obi_rsp_t;

  localparam int unsigned AddrWidth = 32;
  localparam int unsigned DataWidth = 32;
  localparam int unsigned NBytes = DataWidth / 8;
  localparam int unsigned NumManagers = 2;
  localparam int unsigned NumSubordinates = 2;
  localparam int unsigned MrFifoDepth = 256;
  localparam int unsigned SrFifoDepth = 256;
  localparam int unsigned IdWidth = 4;
  localparam int unsigned NoMaps = 2;
  localparam bit unsigned UseIdForRouting = '0;
  localparam bit unsigned Connectivity = '1;

  typedef enum int {
    XbarMem  = 0,
    XbarUart = 1
  } xbar_sub_e;

  localparam addr_map Rvj1AddrMap [NoMaps] = '{
      '{idx: XbarMem,  base: 32'h8000_0000, mask: 32'hffff_4000}, 
      '{idx: XbarUart, base: 32'h6000_0000, mask: 32'hfffff200}
  };
endpackage
