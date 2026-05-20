module mcu_soc import mcu_soc_pkg::*; #(
  parameter  INIT_FILE="",
  parameter  int    INIT_FILE_BIN=0,
  parameter  int    MEM_SIZE_WORDS=4096
  ) (
  input  logic clk,
  input  logic rstn,

  output logic tx,
  input  logic rx
);
  logic [IdWidth-1:0]     instr_req_id;
  logic [AddrWidth-1:0] instr_req_addr;
  logic [DataWidth-1:0] instr_req_data;
  logic [NBytes-1:0]    instr_req_strobe;
  logic                 instr_req_write;
  logic                 instr_req_valid;
  logic                 instr_req_ready;

  logic [IdWidth-1:0]     instr_rsp_id;
  logic [DataWidth-1:0] instr_rsp_data;
  logic                 instr_rsp_error;
  logic                 instr_rsp_valid;
  logic                 instr_rsp_ready;

  logic [IdWidth-1:0]     obi_instr_aid;
  logic                 obi_instr_areq;
  logic                 obi_instr_agnt;
  logic [AddrWidth-1:0] obi_instr_aaddr;
  logic                 obi_instr_awe;
  logic [NBytes-1:0]    obi_instr_abe;
  logic [DataWidth-1:0] obi_instr_awdata;

  logic [IdWidth-1:0]     obi_instr_rid;
  logic                 obi_instr_rvalid;
  logic                 obi_instr_rready;
  logic [DataWidth-1:0] obi_instr_rdata;
  logic                 obi_instr_rerr;

  logic [IdWidth-1:0]     data_req_id;
  logic [AddrWidth-1:0] data_req_addr;
  logic [DataWidth-1:0] data_req_data;
  logic [NBytes-1:0]    data_req_strobe;
  logic                 data_req_write;
  logic                 data_req_valid;
  logic                 data_req_ready;

  logic [IdWidth-1:0]     data_rsp_id;
  logic [DataWidth-1:0] data_rsp_data;
  logic                 data_rsp_error;
  logic                 data_rsp_valid;
  logic                 data_rsp_ready;

  logic [IdWidth-1:0]     obi_data_aid;
  logic                 obi_data_areq;
  logic                 obi_data_agnt;
  logic [AddrWidth-1:0] obi_data_aaddr;
  logic                 obi_data_awe;
  logic [NBytes-1:0]    obi_data_abe;
  logic [DataWidth-1:0] obi_data_awdata;

  logic [IdWidth-1:0]     obi_data_rid;
  logic                 obi_data_rvalid;
  logic                 obi_data_rready;
  logic [DataWidth-1:0] obi_data_rdata;
  logic                 obi_data_rerr;

// Xbar & Obi config
  localparam obi_pkg::xbar_cfg_t xbar_cfg = obi_pkg::xbar_default_cfg(NumManagers, NumSubordinates, AddrWidth, DataWdith, IdWidth);

  localparam bit unsigned [xbar_cfg.Subordinates-1:0] UseSrFifoMask;
  assign UseSrFifoMask[XbarMem] = '0;
  assign UseSrFifoMask[XbarUart] = '1;
  localparam int unsigned SrFifoDepth [xbar_cfg.Subordinates];
  assign SrFifoDepth[XbarMem] = 0;
  assign SrFifoDepth[XbarUart] = 8;

  localparam obi_pkg::obi_if_type_e obi_manager = MANAGER;
  localparam obi_pkg::obi_if_type_e obi_subordinate = SUBORDINATE;

  typedef struct packed {
        logic [xbar_cfg.IdWidth-1:0]              obi_aid;
        logic [$clog2(xbar_cfg.Managers)-1:0]    obi_mid;
  } obi_sub_id;

  localparam type obi_sub_id_t = obi_sub_id;

  `TYPEDEF_OBI_CHANS(mgr_obi_a_t, mgr_obi_r_t, obi_manager, xbar_cfg);

  `TYPEDEF_OBI_CHANS(sub_obi_a_t, sub_obi_r_t, obi_subordinate, xbar_cfg);

  `TYPEDEF_XBAR_ADDR_MAP(addr_map_t, AddrWidth, NumSubordinates);

  localparam addr_map_t Rvj1AddrMap [xbar_cfg.NoMaps] = '{
      '{idx: XbarMem,  base: 32'h8000_0000, mask: 32'hffff_4000}, 
      '{idx: XbarUart, base: 32'h6000_0000, mask: 32'hfffff200}
  };

  `TYPEDEF_XBAR_CONNECTIVITY(Connectivity, NumSubordinates, NumManagers, {{2'b11}, {2'b11}});


  /*
  `TYPEDEF_OBI_A_CHAN(obi_a_t, AddrWidth, DataWidth, IdWidth, NumManagers);

  `TYPEDEF_OBI_R_CHAN(obi_r_t, DataWidth, IdWidth);

  `TYPEDEF_XBAR_ADDR_MAP(addr_map_t, AddrWidth, NumSubordinates);
  */

  mgr_obi_a_t obi_a_chans_mgr       [NumManagers];
  logic obi_agnt_signals_mgr    [NumManagers];
  mgr_obi_r_t obi_r_chans_mgr       [NumManagers];
  logic obi_rready_signals_mgr  [NumManagers];

  sub_obi_a_t obi_a_chans_sub       [NumSubordinates];
  logic obi_agnt_signals_sub    [NumSubordinates];
  sub_obi_r_t obi_r_chans_sub       [NumSubordinates];
  logic obi_rready_signals_sub  [NumSubordinates];

  rvj1_top rvj1_inst (
    .clk_i              (clk),
    .rstn_i             (rstn),

    .instr_req_id_o     (instr_req_id),
    .instr_req_addr_o   (instr_req_addr),
    .instr_req_data_o   (instr_req_data),
    .instr_req_strobe_o (instr_req_strobe),
    .instr_req_write_o  (instr_req_write),
    .instr_req_valid_o  (instr_req_valid),
    .instr_req_ready_i  (instr_req_ready),

    .instr_rsp_id_i     (instr_rsp_id),
    .instr_rsp_data_i   (instr_rsp_data),
    .instr_rsp_error_i  (instr_rsp_error),
    .instr_rsp_valid_i  (instr_rsp_valid),
    .instr_rsp_ready_o  (instr_rsp_ready),

    .data_req_id_o      (data_req_id),
    .data_req_addr_o    (data_req_addr),
    .data_req_data_o    (data_req_data),
    .data_req_strobe_o  (data_req_strobe),
    .data_req_write_o   (data_req_write),
    .data_req_valid_o   (data_req_valid),
    .data_req_ready_i   (data_req_ready),

    .data_rsp_id_i      (data_rsp_id),
    .data_rsp_data_i    (data_rsp_data),
    .data_rsp_error_i   (data_rsp_error),
    .data_rsp_valid_i   (data_rsp_valid),
    .data_rsp_ready_o   (data_rsp_ready),

    .irq_external_i     (1'b0),
    .irq_timer_i        (1'b0),
    .irq_sw_i           (1'b0),
    .irq_lcofi_i        (1'b0),
    .irq_platform_i     ('0),
    .irq_nmi_i          (1'b0)
  );

  mapped2obi #(
    .ADDR_WIDTH(AddrWidth),
    .DATA_WIDTH(DataWidth),
    .IDLEN(IdWidth)) m2o_instr (

    .clk_i  (clk),
    .rstn_i (rstn),

    .mapped_req_id_i     (instr_req_id),
    .mapped_req_addr_i   (instr_req_addr),
    .mapped_req_data_i   (instr_req_data),
    .mapped_req_strobe_i (instr_req_strobe),
    .mapped_req_write_i  (instr_req_write),
    .mapped_req_valid_i  (instr_req_valid),
    .mapped_req_ready_o  (instr_req_ready),

    .mapped_rsp_id_o     (instr_rsp_id),
    .mapped_rsp_data_o   (instr_rsp_data),
    .mapped_rsp_error_o  (instr_rsp_error),
    .mapped_rsp_valid_o  (instr_rsp_valid),
    .mapped_rsp_ready_i  (instr_rsp_ready),

    .obi_aid_o           (obi_instr_aid),
    .obi_areq_o          (obi_instr_areq),
    .obi_agnt_i          (obi_instr_agnt),
    .obi_aaddr_o         (obi_instr_aaddr),
    .obi_awe_o           (obi_instr_awe),
    .obi_abe_o           (obi_instr_abe),
    .obi_awdata_o        (obi_instr_awdata),

    .obi_rid_i           (obi_instr_rid),
    .obi_rvalid_i        (obi_instr_rvalid),
    .obi_rready_o        (obi_instr_rready),
    .obi_rdata_i         (obi_instr_rdata),
    .obi_rerr_i          (obi_instr_rerr)
  );
  assign obi_instr_agnt                       = obi_agnt_signals_mgr[XbarIfu];
  assign obi_a_chans_mgr[XbarIfu].obi_areq    = obi_instr_areq;
  assign obi_a_chans_mgr[XbarIfu].obi_aadr    = obi_instr_aaddr;
  assign obi_a_chans_mgr[XbarIfu].obi_awe     = obi_instr_awe;
  assign obi_a_chans_mgr[XbarIfu].obi_abe     = obi_instr_abe;
  assign obi_a_chans_mgr[XbarIfu].obi_awdata  = obi_instr_awdata;
  assign obi_a_chans_mgr[XbarIfu].obi_aid     = obi_instr_aid;

  assign obi_rready_signals_mgr[XbarIfu]  = obi_instr_rready;
  assign obi_instr_rvalid                 = obi_r_chans_mgr[XbarIfu].obi_rvalid;
  assign obi_instr_rdata                  = obi_r_chans_mgr[XbarIfu].obi_rdata;
  assign obi_instr_rerr                   = obi_r_chans_mgr[XbarIfu].obi_rerr;
  assign obi_instr_rid                    = obi_r_chans_mgr[XbarIfu].obi_rid;

  mapped2obi #(
    .ADDR_WIDTH(AddrWidth),
    .DATA_WIDTH(DataWidth),
    .IDLEN(IdWidth)) m2o_data (

    .mapped_req_id_i     (data_req_id),
    .mapped_req_addr_i   (data_req_addr),
    .mapped_req_data_i   (data_req_data),
    .mapped_req_strobe_i (data_req_strobe),
    .mapped_req_write_i  (data_req_write),
    .mapped_req_valid_i  (data_req_valid),
    .mapped_req_ready_o  (data_req_ready),

    .mapped_rsp_id_o     (data_rsp_id),
    .mapped_rsp_data_o   (data_rsp_data),
    .mapped_rsp_error_o  (data_rsp_error),
    .mapped_rsp_valid_o  (data_rsp_valid),
    .mapped_rsp_ready_i  (data_rsp_ready),

    .obi_aid_o           (obi_data_aid),
    .obi_areq_o          (obi_data_areq),
    .obi_agnt_i          (obi_data_agnt),
    .obi_aaddr_o         (obi_data_aaddr),
    .obi_awe_o           (obi_data_awe),
    .obi_abe_o           (obi_data_abe),
    .obi_awdata_o        (obi_data_awdata),

    .obi_rid_i           (obi_data_rid),
    .obi_rvalid_i        (obi_data_rvalid),
    .obi_rready_o        (obi_data_rready),
    .obi_rdata_i         (obi_data_rdata),
    .obi_rerr_i          (obi_data_rerr)
  );

  assign obi_data_agnt                        = obi_agnt_signals_mgr[XbarLsu];
  assign obi_a_chans_mgr[XbarLsu].obi_areq    = obi_data_areq;
  assign obi_a_chans_mgr[XbarLsu].obi_aadr    = obi_data_aaddr;
  assign obi_a_chans_mgr[XbarLsu].obi_awe     = obi_data_awe;
  assign obi_a_chans_mgr[XbarLsu].obi_abe     = obi_data_abe;
  assign obi_a_chans_mgr[XbarLsu].obi_awdata  = obi_data_awdata;
  assign obi_a_chans_mgr[XbarLsu].obi_aid     = obi_data_aid;

  assign obi_rready_signals_mgr[XbarLsu]  = obi_data_rready;
  assign obi_data_rvalid                  = obi_r_chans_mgr[XbarLsu].obi_rvalid;
  assign obi_data_rdata                   = obi_r_chans_mgr[XbarLsu].obi_rdata;
  assign obi_data_rerr                    = obi_r_chans_mgr[XbarLsu].obi_rerr;
  assign obi_data_rid                     = obi_r_chans_mgr[XbarLsu].obi_rid;


  obi_xbar #(
        .XbarCfg(xbar_cfg),
        
        .mgr_obi_a_t(mgr_obi_a_t),
        .mgr_obi_r_t(mgr_obi_r_t),
        .sub_obi_a_t(sub_obi_a_t),
        .sub_obi_r_t(sub_obi_r_t),
        .addr_map_t(addr_map_t),

        .USE_SR_FIFO_MASK(UseSrFifoMask),
        .SR_FIFO_DEPTHS(SrFifoDepth),

        .CONNECTIVITY(Connectivity)
    ) xbar_param (
        .clk_i(clk),
        .rstn_i(rstn),
        
        .mgr_obi_a_chans(obi_a_chans_mgr),
        .mgr_obi_agnt_signals(obi_agnt_signals_mgr),
        .mgr_obi_r_chans(obi_r_chans_mgr),
        .mgr_obi_rready_signals(obi_rready_signals_mgr),

        .sub_obi_a_chans(obi_a_chans_sub),
        .sub_obi_agnt_signals(obi_agnt_signals_sub),
        .sub_obi_r_chans(obi_r_chans_sub),
        .sub_obi_rready_signals(obi_rready_signals_sub),

        .addr_map_i(Rvj1AddrMap)

    );

  
  obi_ram #(
    .INIT_FILE     (INIT_FILE),
    .INIT_FILE_BIN (INIT_FILE_BIN),
    .MEM_SIZE_WORDS(MEM_SIZE_WORDS),
    .IDLEN         ($bits(obi_sub_id_t))
  ) mem (
    .clk_i  (clk),
    .rstn_i (rstn),

    .obi_aid_i    (obi_a_chans_sub[XbarMem].obi_aid),
    .obi_areq_i   (obi_a_chans_sub[XbarMem].obi_areq),
    .obi_agnt_o   (obi_agnt_signals_sub[XbarMem]),
    .obi_aaddr_i  (obi_a_chans_sub[XbarMem].obi_aadr),
    .obi_awe_i    (obi_a_chans_sub[XbarMem].obi_awe),
    .obi_awdata_i (obi_a_chans_sub[XbarMem].obi_awdata),
    .obi_abe_i    (obi_a_chans_sub[XbarMem].obi_abe),

    .obi_rid_o    (obi_r_chans_sub[XbarMem].obi_rid),
    .obi_rvalid_o (obi_r_chans_sub[XbarMem].obi_rvalid),
    .obi_rready_i (obi_rready_signals_sub[XbarMem]),
    .obi_rdata_o  (obi_r_chans_sub[XbarMem].obi_rdata)
  );

 obi_uart #(
  .OBI_ADDR_WIDTH(AddrWidth),
  .OBI_DATA_WIDTH(DataWidth)
  ) uart (
    .tx(tx),
    //.rx(rx),
    // OBI SLAVE INTERFACE
    //***************************************
    .obi_clk_i(clk),
    .obi_rstn_i(rstn),

    // ADDRESS CHANNEL
    .obi_req_i(obi_a_chans_sub[XbarUart].obi_areq),
    .obi_gnt_o(obi_agnt_signals_sub[XbarUart]),
    .obi_addr_i(obi_a_chans_sub[XbarUart].obi_aadr),
    .obi_we_i(obi_a_chans_sub[XbarUart].obi_awe),
    .obi_wdata_i(obi_a_chans_sub[XbarUart].obi_awdata),
    .obi_be_i(obi_a_chans_sub[XbarUart].obi_abe),

    // RESPONSE CHANNEL
    .obi_rready_i(obi_rready_signals_sub[XbarUart]),
    .obi_rvalid_o(obi_r_chans_sub[XbarUart].obi_rvalid),
    .obi_rdata_o(obi_r_chans_sub[XbarUart].obi_rdata),
    .obi_err_o(obi_r_chans_sub[XbarUart].obi_rerr)
  );

endmodule
