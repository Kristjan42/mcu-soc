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

endpackage
