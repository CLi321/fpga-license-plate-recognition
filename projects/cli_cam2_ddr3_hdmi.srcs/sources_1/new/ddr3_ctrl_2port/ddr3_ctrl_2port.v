/////////////////////////////////////////////////////////////////////////////////
// Company       : 武汉芯路恒科技有限公司
//                 http://xiaomeige.taobao.com
// Web           : http://www.corecourse.cn
// 
// Create Date   : 2019/05/01 00:00:00
// Module Name   : ddr3_ctrl_2port
// Description   : DDR3控制器封装顶层，双端口
// 
// Dependencies  : 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
/////////////////////////////////////////////////////////////////////////////////


module ddr3_ctrl_2port #(
  parameter FIFO_DW            = 16,
  parameter WR_BYTE_ADDR_BEGIN = 0,
  parameter WR_BYTE_ADDR_END   = 1023,
  parameter RD_BYTE_ADDR_BEGIN = 0,
  parameter RD_BYTE_ADDR_END   = 1023,
  parameter FIFO_ADDR_DEPTH = 64
)
(
  // clock reset
  input                ddr3_clk200m  ,
  input                ddr3_rst_n    ,
  output               ddr3_init_done,
  // wr_fifo wr Interface
  input                wrfifo_clr    ,
  input                wrfifo_clk    ,
  input                wrfifo_wren   ,
  input  [FIFO_DW-1:0] wrfifo_din    ,
  output               wrfifo_full   ,
  output [15:0]        wrfifo_wr_cnt ,
  // rd_fifo rd Interface
  input                rdfifo_clr    ,
  input                rdfifo_clk    ,
  input                rdfifo_rden   ,
  output [FIFO_DW-1:0] rdfifo_dout   ,
  output               rdfifo_empty  ,
  output [15:0]        rdfifo_rd_cnt ,
  //DDR3 Interface
  // Inouts
  inout  [31:0]        ddr3_dq       ,
  inout  [3:0]         ddr3_dqs_n    ,
  inout  [3:0]         ddr3_dqs_p    ,
  // Outputs
  output [14:0]        ddr3_addr     ,
  output [2:0]         ddr3_ba       ,
  output               ddr3_ras_n    ,
  output               ddr3_cas_n    ,
  output               ddr3_we_n     ,
  output               ddr3_reset_n  ,
  output [0:0]         ddr3_ck_p     ,
  output [0:0]         ddr3_ck_n     ,
  output [0:0]         ddr3_cke      ,
  output [0:0]         ddr3_cs_n     ,
  output [3:0]         ddr3_dm       ,
  output [0:0]         ddr3_odt      
);

  wire          ui_clk;
  wire          ui_clk_sync_rst;
  wire          mmcm_locked;
  wire          init_calib_complete;

  wire [3:0]    s_axi_awid;
  wire [29:0]   s_axi_awaddr;
  wire [7:0]    s_axi_awlen;
  wire [2:0]    s_axi_awsize;
  wire [1:0]    s_axi_awburst;
  wire [0:0]    s_axi_awlock;
  wire [3:0]    s_axi_awcache;
  wire [2:0]    s_axi_awprot;
  wire [3:0]    s_axi_awqos;
  wire [3:0]    s_axi_awregion;
  wire          s_axi_awvalid;
  wire          s_axi_awready;

  wire [127:0]  s_axi_wdata;
  wire [15:0]   s_axi_wstrb;
  wire          s_axi_wlast;
  wire          s_axi_wvalid;
  wire          s_axi_wready;

  wire [3:0]    s_axi_bid;
  wire [1:0]    s_axi_bresp;
  wire          s_axi_bvalid;
  wire          s_axi_bready;

  wire [3:0]    s_axi_arid;
  wire [29:0]   s_axi_araddr;
  wire [7:0]    s_axi_arlen;
  wire [2:0]    s_axi_arsize;
  wire [1:0]    s_axi_arburst;
  wire [0:0]    s_axi_arlock;
  wire [3:0]    s_axi_arcache;
  wire [2:0]    s_axi_arprot;
  wire [3:0]    s_axi_arqos;
  wire [3:0]    s_axi_arregion;
  wire          s_axi_arvalid;
  wire          s_axi_arready;

  wire [3:0]    s_axi_rid;
  wire [127:0]  s_axi_rdata;
  wire [1:0]    s_axi_rresp;
  wire          s_axi_rlast;
  wire          s_axi_rvalid;
  wire          s_axi_rready;

  assign ddr3_init_done = mmcm_locked && init_calib_complete;

  fifo_axi4_adapter #(
    .FIFO_DW                (FIFO_DW             ),
    .WR_AXI_BYTE_ADDR_BEGIN (WR_BYTE_ADDR_BEGIN  ),
    .WR_AXI_BYTE_ADDR_END   (WR_BYTE_ADDR_END    ),
    .RD_AXI_BYTE_ADDR_BEGIN (RD_BYTE_ADDR_BEGIN  ),
    .RD_AXI_BYTE_ADDR_END   (RD_BYTE_ADDR_END    ),

    .AXI_DATA_WIDTH         (128                 ),
    .AXI_ADDR_WIDTH         (30                 ),
    .AXI_ID                 (4'b0000             ),
    .AXI_BURST_LEN          (8'd31               ),  //burst length = 32
    .FIFO_ADDR_DEPTH        (FIFO_ADDR_DEPTH     )
  )
  fifo_axi4_adapter_inst (
    //clock reset
    .clk                 (ui_clk              ),
    .reset               (~init_calib_complete),
    // wr_fifo wr Interface
    .wrfifo_clr          (wrfifo_clr          ),
    .wrfifo_clk          (wrfifo_clk          ),
    .wrfifo_wren         (wrfifo_wren         ),
    .wrfifo_din          (wrfifo_din          ),
    .wrfifo_full         (wrfifo_full         ),
    .wrfifo_wr_cnt       (wrfifo_wr_cnt       ),
    // rd_fifo rd Interface
    .rdfifo_clr          (rdfifo_clr          ),
    .rdfifo_clk          (rdfifo_clk          ),
    .rdfifo_rden         (rdfifo_rden         ),
    .rdfifo_dout         (rdfifo_dout         ),
    .rdfifo_empty        (rdfifo_empty        ),
    .rdfifo_rd_cnt       (rdfifo_rd_cnt       ),
    // MASTER Interface Write Address Ports
    .m_axi_awid          (s_axi_awid          ),
    .m_axi_awaddr        (s_axi_awaddr        ),
    .m_axi_awlen         (s_axi_awlen         ),
    .m_axi_awsize        (s_axi_awsize        ),
    .m_axi_awburst       (s_axi_awburst       ),
    .m_axi_awlock        (s_axi_awlock        ),
    .m_axi_awcache       (s_axi_awcache       ),
    .m_axi_awprot        (s_axi_awprot        ),
    .m_axi_awqos         (s_axi_awqos         ),
    .m_axi_awregion      (s_axi_awregion      ),
    .m_axi_awvalid       (s_axi_awvalid       ),
    .m_axi_awready       (s_axi_awready       ),
    // Slave Interface Write Data Ports
    .m_axi_wdata         (s_axi_wdata         ),
    .m_axi_wstrb         (s_axi_wstrb         ),
    .m_axi_wlast         (s_axi_wlast         ),
    .m_axi_wvalid        (s_axi_wvalid        ),
    .m_axi_wready        (s_axi_wready        ),
    // Slave Interface Write Response Ports
    .m_axi_bid           (s_axi_bid           ),
    .m_axi_bresp         (s_axi_bresp         ),
    .m_axi_bvalid        (s_axi_bvalid        ),
    .m_axi_bready        (s_axi_bready        ),
    // Slave Interface Read Address Ports
    .m_axi_arid          (s_axi_arid          ),
    .m_axi_araddr        (s_axi_araddr        ),
    .m_axi_arlen         (s_axi_arlen         ),
    .m_axi_arsize        (s_axi_arsize        ),
    .m_axi_arburst       (s_axi_arburst       ),
    .m_axi_arlock        (s_axi_arlock        ),
    .m_axi_arcache       (s_axi_arcache       ),
    .m_axi_arprot        (s_axi_arprot        ),
    .m_axi_arqos         (s_axi_arqos         ),
    .m_axi_arregion      (s_axi_arregion      ),
    .m_axi_arvalid       (s_axi_arvalid       ),
    .m_axi_arready       (s_axi_arready       ),
    // Slave Interface Read Data Ports
    .m_axi_rid           (s_axi_rid           ),
    .m_axi_rdata         (s_axi_rdata         ),
    .m_axi_rresp         (s_axi_rresp         ),
    .m_axi_rlast         (s_axi_rlast         ),
    .m_axi_rvalid        (s_axi_rvalid        ),
    .m_axi_rready        (s_axi_rready        )
  );

  mig_7series_0 u_mig_7series_0 (
    // Memory interface ports
    .ddr3_addr            (ddr3_addr           ),
    .ddr3_ba              (ddr3_ba             ),
    .ddr3_cas_n           (ddr3_cas_n          ),
    .ddr3_ck_n            (ddr3_ck_n           ),
    .ddr3_ck_p            (ddr3_ck_p           ),
    .ddr3_cke             (ddr3_cke            ),
    .ddr3_ras_n           (ddr3_ras_n          ),
    .ddr3_reset_n         (ddr3_reset_n        ),
    .ddr3_we_n            (ddr3_we_n           ),
    .ddr3_dq              (ddr3_dq             ),
    .ddr3_dqs_n           (ddr3_dqs_n          ),
    .ddr3_dqs_p           (ddr3_dqs_p          ),
    .init_calib_complete  (init_calib_complete ),
    .ddr3_cs_n            (ddr3_cs_n           ),
    .ddr3_dm              (ddr3_dm             ),
    .ddr3_odt             (ddr3_odt            ),
    // Application interface ports
    .ui_clk               (ui_clk              ),
    .ui_clk_sync_rst      (ui_clk_sync_rst     ),
    .mmcm_locked          (mmcm_locked         ),
    .aresetn              (ddr3_rst_n          ),
    .app_sr_req           (1'b0                ),
    .app_ref_req          (1'b0                ),
    .app_zq_req           (1'b0                ),
    .app_sr_active        (                    ),
    .app_ref_ack          (                    ),
    .app_zq_ack           (                    ),
    // Slave Interface Write Address Ports
    .s_axi_awid           (s_axi_awid          ),
    .s_axi_awaddr         (s_axi_awaddr        ),
    .s_axi_awlen          (s_axi_awlen         ),
    .s_axi_awsize         (s_axi_awsize        ),
    .s_axi_awburst        (s_axi_awburst       ),
    .s_axi_awlock         (s_axi_awlock        ),
    .s_axi_awcache        (s_axi_awcache       ),
    .s_axi_awprot         (s_axi_awprot        ),
    .s_axi_awqos          (s_axi_awqos         ),
    .s_axi_awvalid        (s_axi_awvalid       ),
    .s_axi_awready        (s_axi_awready       ),
    // Slave Interface Write Data Ports
    .s_axi_wdata          (s_axi_wdata         ),
    .s_axi_wstrb          (s_axi_wstrb         ),
    .s_axi_wlast          (s_axi_wlast         ),
    .s_axi_wvalid         (s_axi_wvalid        ),
    .s_axi_wready         (s_axi_wready        ),
    // Slave Interface Write Response Ports
    .s_axi_bid            (s_axi_bid           ),
    .s_axi_bresp          (s_axi_bresp         ),
    .s_axi_bvalid         (s_axi_bvalid        ),
    .s_axi_bready         (s_axi_bready        ),
    // Slave Interface Read Address Ports
    .s_axi_arid           (s_axi_arid          ),
    .s_axi_araddr         (s_axi_araddr        ),
    .s_axi_arlen          (s_axi_arlen         ),
    .s_axi_arsize         (s_axi_arsize        ),
    .s_axi_arburst        (s_axi_arburst       ),
    .s_axi_arlock         (s_axi_arlock        ),
    .s_axi_arcache        (s_axi_arcache       ),
    .s_axi_arprot         (s_axi_arprot        ),
    .s_axi_arqos          (s_axi_arqos         ),
    .s_axi_arvalid        (s_axi_arvalid       ),
    .s_axi_arready        (s_axi_arready       ),
    // Slave Interface Read Data Ports
    .s_axi_rid            (s_axi_rid           ),
    .s_axi_rdata          (s_axi_rdata         ),
    .s_axi_rresp          (s_axi_rresp         ),
    .s_axi_rlast          (s_axi_rlast         ),
    .s_axi_rvalid         (s_axi_rvalid        ),
    .s_axi_rready         (s_axi_rready        ),
    // System Clock Ports
    .sys_clk_i            (ddr3_clk200m        ),
    .sys_rst              (ddr3_rst_n          ) //active low
  );

endmodule