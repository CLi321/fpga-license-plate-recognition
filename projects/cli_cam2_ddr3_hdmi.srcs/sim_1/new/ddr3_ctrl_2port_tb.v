/////////////////////////////////////////////////////////////////////////////////
// Company       : 武汉芯路恒科技有限公司
//                 http://xiaomeige.taobao.com
// Web           : http://www.corecourse.cn
// 
// Create Date   : 2019/05/01 00:00:00
// Module Name   : ddr3_ctrl_2port_tb
// Description   : ddr3_ctrl_2port模块仿真文件
// 
// Dependencies  : 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
/////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

module ddr3_ctrl_2port_tb;

  reg           ddr3_clk200m;
  reg           ddr3_rst_n;
  wire          ddr3_init_done;
  //wr_fifo Interface
  reg           wrfifo_clr;
  reg           wrfifo_clk;
  reg           wrfifo_wren;
  reg    [15:0] wrfifo_din;
  wire          wrfifo_full;
  wire   [8:0]  wrfifo_wr_cnt;
  //rd_fifo Interface
  reg           rdfifo_clr;
  reg           rdfifo_clk;
  reg           rdfifo_rden;
  wire   [15:0] rdfifo_dout;
  wire          rdfifo_empty;
  wire   [8:0]  rdfifo_rd_cnt;

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

  initial ddr3_clk200m = 1'b1;
  always #2.5 ddr3_clk200m = ~ddr3_clk200m;

  initial wrfifo_clk = 1'b1;
  always #5 wrfifo_clk = ~wrfifo_clk;

  initial rdfifo_clk = 1'b1;
  always #5 rdfifo_clk = ~rdfifo_clk;

  initial begin
    ddr3_rst_n = 1'b0;
    wrfifo_clr  = 1'b1;
    wrfifo_wren = 1'b0;
    wrfifo_din  = 16'd0;
    rdfifo_clr  = 1'b1;
    rdfifo_rden = 1'b0;
    #201;
    ddr3_rst_n = 1'b1;
    #200;
    wrfifo_clr  = 1'b0;
    rdfifo_clr  = 1'b0;
    @(posedge ddr3_init_done);
    #200;
    wr_data(16'd1,16'd1024);
    #2000;
    rdfifo_clr  = 1'b1;
    #20;
    rdfifo_clr  = 1'b0;
    #2000;
    rd_data(16'd1024);
    #5000;
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
      repeat(wr_data_cnt )
      begin        
        @(posedge wrfifo_clk);
        wrfifo_din = wrfifo_din + 1'b1;
      end
      #1 wrfifo_wren = 1'b0;
    end
  endtask

  task rd_data;
    input [15:0]rd_data_cnt;
    begin
      rdfifo_rden = 1'b0;
      @(posedge rdfifo_clk);
      #1 rdfifo_rden = 1'b1;
      repeat(rd_data_cnt )
      begin
        @(posedge rdfifo_clk);
      end
      #1 rdfifo_rden = 1'b0;
    end
  endtask

  ddr3_ctrl_2port #(
    .FIFO_DW            (16  ),
    .WR_BYTE_ADDR_BEGIN (0   ),
    .WR_BYTE_ADDR_END   (2047),
    .RD_BYTE_ADDR_BEGIN (0   ),
    .RD_BYTE_ADDR_END   (2047),
    .FIFO_ADDR_DEPTH    (64  )
  )
  ddr3_ctrl_2port(
    // clock reset
    .ddr3_clk200m  (ddr3_clk200m  ),
    .ddr3_rst_n    (ddr3_rst_n    ),
    .ddr3_init_done(ddr3_init_done),
    // wr_fifo wr Interface
    .wrfifo_clr    (wrfifo_clr    ),
    .wrfifo_clk    (wrfifo_clk    ),
    .wrfifo_wren   (wrfifo_wren   ),
    .wrfifo_din    (wrfifo_din    ),
    .wrfifo_full   (wrfifo_full   ),
    .wrfifo_wr_cnt (wrfifo_wr_cnt ),
    // rd_fifo rd Interface
    .rdfifo_clr    (rdfifo_clr    ),
    .rdfifo_clk    (rdfifo_clk    ),
    .rdfifo_rden   (rdfifo_rden   ),
    .rdfifo_dout   (rdfifo_dout   ),
    .rdfifo_empty  (rdfifo_empty  ),
    .rdfifo_rd_cnt (rdfifo_rd_cnt ),
    //DDR3 Interface
    // Inouts
    .ddr3_dq       (ddr3_dq       ),
    .ddr3_dqs_n    (ddr3_dqs_n    ),
    .ddr3_dqs_p    (ddr3_dqs_p    ),
    // Outputs      
    .ddr3_addr     (ddr3_addr     ),
    .ddr3_ba       (ddr3_ba       ),
    .ddr3_ras_n    (ddr3_ras_n    ),
    .ddr3_cas_n    (ddr3_cas_n    ),
    .ddr3_we_n     (ddr3_we_n     ),
    .ddr3_reset_n  (ddr3_reset_n  ),
    .ddr3_ck_p     (ddr3_ck_p     ),
    .ddr3_ck_n     (ddr3_ck_n     ),
    .ddr3_cke      (ddr3_cke      ),
    .ddr3_cs_n     (ddr3_cs_n     ),
    .ddr3_dm       (ddr3_dm       ),
    .ddr3_odt      (ddr3_odt      )
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


endmodule