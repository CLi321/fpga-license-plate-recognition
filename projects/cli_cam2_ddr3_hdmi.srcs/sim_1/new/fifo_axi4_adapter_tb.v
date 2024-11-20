/////////////////////////////////////////////////////////////////////////////////
// Company       : 武汉芯路恒科技有限公司
//                 http://xiaomeige.taobao.com
// Web           : http://www.corecourse.cn
// 
// Create Date   : 2019/05/01 00:00:00
// Module Name   : fifo_axi4_adapter_tb
// Description   : fifo_axi4_adapter模块仿真文件
// 
// Dependencies  : 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
/////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module fifo_axi4_adapter_tb;

  parameter SIM_DATA_BEGIN = 100;
  parameter SIM_DATA_CNT   = 1024;

  reg           aresetn;
  reg           sys_clk_i;
  reg           sys_rst;

  reg  [15:0]   expect_rd_data;
  //wr_fifo Interface
  reg           wrfifo_clr;
  reg           wrfifo_clk;
  reg  [15:0]   wrfifo_din;
  reg           wrfifo_wren;
  //rd_fifo Interface
  reg           rdfifo_clr;
  reg           rdfifo_clk;
  reg           rdfifo_rden;
  wire [15:0]   rdfifo_dout;
  wire          rdfifo_empty;
  //mig Interface
  wire          mmcm_locked;
  wire          ui_clk;
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

  wire [14:0]   ddr3_addr;
  wire [2:0]    ddr3_ba;
  wire          ddr3_cas_n;
  wire [0:0]    ddr3_ck_n;
  wire [0:0]    ddr3_ck_p;
  wire [0:0]    ddr3_cke;
  wire          ddr3_ras_n;
  wire          ddr3_reset_n;
  wire          ddr3_we_n;
  wire [31:0]   ddr3_dq;
  wire [3:0]    ddr3_dqs_n;
  wire [3:0]    ddr3_dqs_p;
  wire [0:0]    ddr3_cs_n;
  wire [3:0]    ddr3_dm;
  wire [0:0]    ddr3_odt;

  initial sys_clk_i = 1'b1;
  always #2.5 sys_clk_i = ~sys_clk_i;

  initial wrfifo_clk = 1'b1;
  always #5 wrfifo_clk = ~wrfifo_clk;

  initial rdfifo_clk = 1'b1;
  always #5 rdfifo_clk = ~rdfifo_clk;

  initial begin
    sys_rst = 1'b0;
    aresetn = 1'b0;
    expect_rd_data = 16'd0;
    wrfifo_clr  = 1'b1;
    wrfifo_wren = 1'b0;
    wrfifo_din  = 16'd0;
    rdfifo_clr  = 1'b1;
    rdfifo_rden = 1'b0;
    #201;
    sys_rst = 1'b1;
    aresetn = 1'b1;
    @(posedge mmcm_locked);
    #200;
    wrfifo_clr  = 1'b0;
    rdfifo_clr  = 1'b0;
    @(posedge init_calib_complete);
    #200;

    wr_data(SIM_DATA_BEGIN,SIM_DATA_CNT);
    #2000;
    rdfifo_clr  = 1'b1;
    #20;
    rdfifo_clr  = 1'b0;
    #2000;
    wait(rdfifo_empty == 1'b0)
    rd_data(SIM_DATA_BEGIN,SIM_DATA_CNT);

    #5000;
    $display("SIM is successfully");
    $stop;
  end

  task wr_data;
    input [15:0]data_begin;
    input [15:0]wr_data_cnt;
    begin
      wrfifo_wren = 1'b0;
      wrfifo_din  = data_begin;
      @(posedge wrfifo_clk);
      #1 wrfifo_wren = 1'b1;
      repeat(wr_data_cnt)
      begin        
        @(posedge wrfifo_clk);
        #1 wrfifo_din = wrfifo_din + 1'b1;
      end
      #1 wrfifo_wren = 1'b0;
    end
  endtask

  task rd_data;
    input [15:0]data_begin;
    input [15:0]rd_data_cnt;
    begin
      rdfifo_rden = 1'b0;
      expect_rd_data = data_begin;
      @(posedge rdfifo_clk);
      #1 rdfifo_rden = 1'b1;
      repeat(rd_data_cnt)
      begin
        @(posedge rdfifo_clk);
        #1;
        if(rdfifo_dout != expect_rd_data)
        begin
          $display("SIM is failed");
          $finish;
        end
        expect_rd_data = expect_rd_data + 1'b1;
      end
      #1 rdfifo_rden = 1'b0;
    end
  endtask


  fifo_axi4_adapter #(
    .FIFO_DW                (16        ),
    .WR_AXI_BYTE_ADDR_BEGIN (0         ),
    .WR_AXI_BYTE_ADDR_END   (SIM_DATA_CNT*2 -1   ),
    .RD_AXI_BYTE_ADDR_BEGIN (0         ),
    .RD_AXI_BYTE_ADDR_END   (SIM_DATA_CNT*2 -1   ),

    .AXI_DATA_WIDTH         ( 128      ),
    .AXI_ADDR_WIDTH         ( 30       ),
    .AXI_ID_WIDTH           ( 4        ),
    .AXI_ID                 ( 4'b0000  ),
    .AXI_BURST_LEN          ( 8'd31    ),  //burst length = 32
    .FIFO_ADDR_DEPTH        ( 64       )
  )
  fifo_axi4_adapter_inst (
    // clock reset
    .clk                 (ui_clk              ),
    .reset               (~init_calib_complete),
    // wr_fifo wr Interface
    .wrfifo_clr          (wrfifo_clr          ),
    .wrfifo_clk          (wrfifo_clk          ),
    .wrfifo_wren         (wrfifo_wren         ),
    .wrfifo_din          (wrfifo_din          ),
    .wrfifo_full         (                    ),
    .wrfifo_wr_cnt       (                    ),
    // rd_fifo rd Interface
    .rdfifo_clr          (rdfifo_clr          ),
    .rdfifo_clk          (rdfifo_clk          ),
    .rdfifo_rden         (rdfifo_rden         ),
    .rdfifo_dout         (rdfifo_dout         ),
    .rdfifo_empty        (rdfifo_empty        ),
    .rdfifo_rd_cnt       (                    ),
    // Master Interface Write Address Ports
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
    // Master Interface Write Data Ports
    .m_axi_wdata         (s_axi_wdata         ),
    .m_axi_wstrb         (s_axi_wstrb         ),
    .m_axi_wlast         (s_axi_wlast         ),
    .m_axi_wvalid        (s_axi_wvalid        ),
    .m_axi_wready        (s_axi_wready        ),
    // Master Interface Write Response Ports
    .m_axi_bid           (s_axi_bid           ),
    .m_axi_bresp         (s_axi_bresp         ),
    .m_axi_bvalid        (s_axi_bvalid        ),
    .m_axi_bready        (s_axi_bready        ),
    // Master Interface Read Address Ports
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
    // Master Interface Read Data Ports
    .m_axi_rid           (s_axi_rid           ),
    .m_axi_rdata         (s_axi_rdata         ),
    .m_axi_rresp         (s_axi_rresp         ),
    .m_axi_rlast         (s_axi_rlast         ),
    .m_axi_rvalid        (s_axi_rvalid        ),
    .m_axi_rready        (s_axi_rready        )
  );

  mig_7series_0 u_mig_7series_0 (
    // Memory interface ports
    .ddr3_addr           (ddr3_addr           ),
    .ddr3_ba             (ddr3_ba             ),
    .ddr3_cas_n          (ddr3_cas_n          ),
    .ddr3_ck_n           (ddr3_ck_n           ),
    .ddr3_ck_p           (ddr3_ck_p           ),
    .ddr3_cke            (ddr3_cke            ),
    .ddr3_ras_n          (ddr3_ras_n          ),
    .ddr3_reset_n        (ddr3_reset_n        ),
    .ddr3_we_n           (ddr3_we_n           ),
    .ddr3_dq             (ddr3_dq             ),
    .ddr3_dqs_n          (ddr3_dqs_n          ),
    .ddr3_dqs_p          (ddr3_dqs_p          ),
    .init_calib_complete (init_calib_complete ),
    .ddr3_cs_n           (ddr3_cs_n           ),
    .ddr3_dm             (ddr3_dm             ),
    .ddr3_odt            (ddr3_odt            ),
    // Application interface ports
    .ui_clk              (ui_clk              ),
    .ui_clk_sync_rst     (ui_clk_sync_rst     ),
    .mmcm_locked         (mmcm_locked         ),
    .aresetn             (aresetn             ),
    .app_sr_req          (1'b0                ),
    .app_ref_req         (1'b0                ),
    .app_zq_req          (1'b0                ),
    .app_sr_active       (                    ),
    .app_ref_ack         (                    ),
    .app_zq_ack          (                    ),
    // Slave Interface Write Address Ports      
    .s_axi_awid          (s_axi_awid          ),
    .s_axi_awaddr        (s_axi_awaddr        ),
    .s_axi_awlen         (s_axi_awlen         ),
    .s_axi_awsize        (s_axi_awsize        ),
    .s_axi_awburst       (s_axi_awburst       ),
    .s_axi_awlock        (s_axi_awlock        ),
    .s_axi_awcache       (s_axi_awcache       ),
    .s_axi_awprot        (s_axi_awprot        ),
    .s_axi_awqos         (s_axi_awqos         ),
    .s_axi_awvalid       (s_axi_awvalid       ),
    .s_axi_awready       (s_axi_awready       ),
    // Slave Interface Write Data Ports
    .s_axi_wdata         (s_axi_wdata         ),
    .s_axi_wstrb         (s_axi_wstrb         ),
    .s_axi_wlast         (s_axi_wlast         ),
    .s_axi_wvalid        (s_axi_wvalid        ),
    .s_axi_wready        (s_axi_wready        ),
    // Slave Interface Write Response Ports     
    .s_axi_bid           (s_axi_bid           ),
    .s_axi_bresp         (s_axi_bresp         ),
    .s_axi_bvalid        (s_axi_bvalid        ),
    .s_axi_bready        (s_axi_bready        ),
    // Slave Interface Read Address Ports       
    .s_axi_arid          (s_axi_arid          ),
    .s_axi_araddr        (s_axi_araddr        ),
    .s_axi_arlen         (s_axi_arlen         ),
    .s_axi_arsize        (s_axi_arsize        ),
    .s_axi_arburst       (s_axi_arburst       ),
    .s_axi_arlock        (s_axi_arlock        ),
    .s_axi_arcache       (s_axi_arcache       ),
    .s_axi_arprot        (s_axi_arprot        ),
    .s_axi_arqos         (s_axi_arqos         ),
    .s_axi_arvalid       (s_axi_arvalid       ),
    .s_axi_arready       (s_axi_arready       ),
    // Slave Interface Read Data Ports
    .s_axi_rid           (s_axi_rid           ),
    .s_axi_rdata         (s_axi_rdata         ),
    .s_axi_rresp         (s_axi_rresp         ),
    .s_axi_rlast         (s_axi_rlast         ),
    .s_axi_rvalid        (s_axi_rvalid        ),
    .s_axi_rready        (s_axi_rready        ),
    // System Clock Ports
    .sys_clk_i           (sys_clk_i           ),
    .sys_rst             (sys_rst             ) //active low
  );

  ddr3_model ddr3_model1
  (
    .rst_n  (ddr3_reset_n ),
    .ck     (ddr3_ck_p    ),
    .ck_n   (ddr3_ck_n    ),
    .cke    (ddr3_cke     ),
    .cs_n   (ddr3_cs_n    ),
    .ras_n  (ddr3_ras_n   ),
    .cas_n  (ddr3_cas_n   ),
    .we_n   (ddr3_we_n    ),
    .dm_tdqs(ddr3_dm[3:2] ),
    .ba     (ddr3_ba      ),
    .addr   (ddr3_addr),
    .dq     (ddr3_dq[31:16]),
    .dqs    (ddr3_dqs_p[3:2]   ),
    .dqs_n  (ddr3_dqs_n[3:2]),
    .tdqs_n (             ),
    .odt    (ddr3_odt     )
  );

  ddr3_model ddr3_model2
  (
    .rst_n  (ddr3_reset_n ),
    .ck     (ddr3_ck_p    ),
    .ck_n   (ddr3_ck_n    ),
    .cke    (ddr3_cke     ),
    .cs_n   (ddr3_cs_n    ),
    .ras_n  (ddr3_ras_n   ),
    .cas_n  (ddr3_cas_n   ),
    .we_n   (ddr3_we_n    ),
    .dm_tdqs(ddr3_dm[1:0] ),
    .ba     (ddr3_ba      ),
    .addr   (ddr3_addr),
    .dq     (ddr3_dq[15:0]),
    .dqs    (ddr3_dqs_p[1:0]   ),
    .dqs_n  (ddr3_dqs_n[1:0]),
    .tdqs_n (             ),
    .odt    (ddr3_odt     )
  );

`ifdef SAVE_WAVE_FILE
  // dump fsdb file for debussy
  initial
  begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars;
  end
`endif

endmodule