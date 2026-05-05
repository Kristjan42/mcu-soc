package mcu_soc_pkg;

  import obi_pkg::*;

  localparam int unsigned AddrWidth = 32;
  localparam int unsigned DataWidth = 32;
  localparam int unsigned NBytes = DataWidth / 8;
  localparam int unsigned NumManagers = 2;
  localparam int unsigned NumSubordinates = 2;
  //localparam int unsigned MrFifoDepth = 256;
  //localparam int unsigned SrFifoDepth = 256;
  localparam int unsigned IdWidth = 4;
  localparam int unsigned NoMaps = 2;
  //localparam bit unsigned UseIdForRouting = '0;

  typedef enum int {
    XbarMem  = 0,
    XbarUart = 1
  } xbar_sub_e;

  typedef enum int {
    XbarLsu   = 0,
    XbarIfu   = 1
  } xbar_mgr_e;

  /*
  localparam addr_map Rvj1AddrMap [NoMaps] = '{
      '{idx: XbarMem,  base: 32'h8000_0000, mask: 32'hffff_4000}, 
      '{idx: XbarUart, base: 32'h6000_0000, mask: 32'hfffff200}
  };
  */
endpackage
