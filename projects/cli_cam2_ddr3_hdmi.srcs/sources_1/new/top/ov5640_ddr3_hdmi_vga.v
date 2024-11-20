/////////////////////////////////////////////////////////////////////////////////
// Company       : 武汉芯路恒科技有限公司
//                 http://xiaomeige.taobao.com
// Web           : http://www.corecourse.cn
// 
// Create Date   : 2019/05/01 00:00:00
// Module Name   : ov5640_ddr3_hdmi
// Description   : 摄像头采集数据，DDR3缓存，HDMI接口输出
// 
// Dependencies  : 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
/////////////////////////////////////////////////////////////////////////////////

module ov5640_ddr3_hdmi_vga(
  //System clock reset
  input           clk50m        , //系统时钟输入，50MHz
  input           reset_n       , //复位信号输入
  //LED
  output [3:0]    led           ,

  //camera interface
  output          camera_sclk   ,
  inout           camera_sdat   ,
  input           camera_vsync  ,
  input           camera_href   ,
  input           camera_pclk   ,
//  output          camera_xclk   ,
  input  [7:0]    camera_data   ,
  output          camera_rst_n  ,
  output          camera_pwdn   ,

  //hdmi interface
  output          hdmi_clk_p   ,
  output          hdmi_clk_n   ,
  output [2:0]    hdmi_dat_p   ,
  output [2:0]    hdmi_dat_n   ,
  output          HDMI_OUT_EN2,

  //DDR3 Interface
  // Inouts
  inout  [31:0]   ddr3_dq       ,
  inout  [3:0]    ddr3_dqs_n    ,
  inout  [3:0]    ddr3_dqs_p    ,
  // Outputs      
  output [14:0]   ddr3_addr     ,
  output [2:0]    ddr3_ba       ,
  output          ddr3_ras_n    ,
  output          ddr3_cas_n    ,
  output          ddr3_we_n     ,
  output          ddr3_reset_n  ,
  output [0:0]    ddr3_ck_p     ,
  output [0:0]    ddr3_ck_n     ,
  output [0:0]    ddr3_cke      ,
  output [0:0]    ddr3_cs_n     ,
  output [3:0]    ddr3_dm       ,
  output [0:0]    ddr3_odt         


);
    assign  HDMI_OUT_EN2 = 1;
    
//Resolution_1280x720  像素时钟为74.25MHz
parameter DISP_WIDTH  = 800;
parameter DISP_HEIGHT = 600;

//*********************************
//Internal connect
//*********************************
  //clock
  wire          pll_locked;
  wire          loc_clk50m;
  wire          loc_clk100m;
  wire          loc_clk24m;
  wire          loc_clk200m;
  wire          dvi_pll_locked;
  wire          pixelclk;
  wire          pixelclk5x;
  //reset
  wire          g_rst_p;
  //camera interface
  wire          camera_init_done;
  wire          pclk_bufg_o;
  wire [15:0]   image_data;
  wire          image_data_valid;
  wire          image_data_hs;
  wire          image_data_vs;
  //wr_fifo Interface
  wire          wrfifo_clr;
  wire          wrfifo_wren;
  wire [15:0]   wrfifo_din;
  //rd_fifo Interface
  wire          rdfifo_clr;
  wire          rdfifo_rden;
  wire [15 :0]  rdfifo_dout;
  //mig Interface 
  wire          ddr3_rst_n;
  wire          ddr3_init_done;
  //tft
  wire          frame_begin;

  wire [11:0]   disp_h_addr;
  wire [11:0]   disp_v_addr;
  wire          disp_data_req;
  wire [23:0]   disp_data;
  wire [7:0]    disp_red;
  wire [7:0]    disp_green;
  wire [7:0]    disp_blue;
  wire          disp_pclk;

  assign ddr3_rst_n = pll_locked;
  assign g_rst_p = (~ddr3_init_done)| (~dvi_pll_locked);

  assign led = {camera_init_done,camera_rst_n,ddr3_init_done,pll_locked};

  pll pll
  (
    // Clock out ports
    .clk_out1 (loc_clk50m   ), // output clk_out1
    .clk_out2 (loc_clk200m  ), // output clk_out2
    .clk_out3 (loc_clk100m  ), // output clk_out3
    .clk_out4 (loc_clk24m   ), // output clk_out3
    // Status and control signals
    .resetn   (reset_n      ), // input reset
    .locked   (pll_locked   ), // output locked
    // Clock in ports
    .clk_in1  (clk50m       )  // input clk_in1
  );

  dvi_pll dvi_pll
  (
    // Clock out ports
    .clk_out1(pixelclk       ),// output clk_out1
    .clk_out2(pixelclk5x     ),// output clk_out2
    // Status and control signals
    .resetn  (reset_n        ),// input reset
    .locked  (dvi_pll_locked ),// output locked
    // Clock in ports
    .clk_in1 (loc_clk100m    ) // input clk_in1
  );

//  assign camera_xclk = loc_clk24m;

    camera_init
  #(
    .CAMERA_TYPE    ( "ov5640"     ),//"ov5640" or "ov7725"
    .IMAGE_TYPE     ( 0            ),// 0: RGB; 1: JPEG
    .IMAGE_WIDTH    ( DISP_WIDTH  ),// 图片宽度
    .IMAGE_HEIGHT   ( DISP_HEIGHT ),// 图片高度
    .IMAGE_FLIP_EN  ( 0            ),// 0: 不翻转，1: 上下翻转
    .IMAGE_MIRROR_EN( 0            ) // 0: 不镜像，1: 左右镜像
  )camera_init
  (
    .Clk         (loc_clk50m        ),
    .Rst_n       (~g_rst_p          ),
    .Init_Done   (camera_init_done  ),
    .camera_rst_n(camera_rst_n                  ),
    .camera_pwdn (camera_pwdn                  ),
    .i2c_sclk    (camera_sclk       ),
    .i2c_sdat    (camera_sdat       )
  );

  BUFG BUFG_inst (
    .O(pclk_bufg_o ), // 1-bit output: Clock output
    .I(camera_pclk )  // 1-bit input: Clock input
  );

  DVP_Capture DVP_Capture(
    .Rst_p      (g_rst_p          ),//input
    .PCLK       (pclk_bufg_o      ),//input
    .Vsync      (camera_vsync     ),//input
    .Href       (camera_href      ),//input
    .Data       (camera_data      ),//input     [7:0]

    .ImageState (                 ),//output reg
    .DataValid  (image_data_valid ),//output
    .DataPixel  (image_data       ),//output    [15:0]
    .DataHs     (image_data_hs    ),//output
    .DataVs     (image_data_vs    ),//output
    .Xaddr      (                 ),//output    [11:0]
    .Yaddr      (                 ) //output    [11:0]
  );

//---------------------------------------------
//仅仿真用，正常功能时，将下面sim_dat_gen模块进行屏蔽
//仿真时，取消屏蔽sim_dat_gen模块，将DVP_Capture模块屏蔽
//---------------------------------------------
//  sim_dat_gen #(
//    .DISP_WIDTH  (DISP_WIDTH   ),
//    .DISP_HEIGHT (DISP_HEIGHT  ),
//    .DATA_WIDTH  (16           )
//  )
//  sim_dat_gen(
//    .clk          (pclk_bufg_o     ),
//    .reset        (g_rst_p         ),
//    .gen_en       (camera_init_done),
//    .sim_dat      (image_data      ),
//    .sim_dat_vaild(image_data_valid)
//  );
//-------------------------------------------

wire         post_frame_vsync          ;
wire         post_frame_href          ;
wire         post_frame_de             ;    
wire  [23:0] post_rgb                  ;


//  assign wrfifo_wren = image_data_valid;
//  assign wrfifo_din = image_data;
//  assign wrfifo_clr = ~camera_init_done;
  assign wrfifo_wren  = post_frame_de;
  assign wrfifo_din   = {post_rgb[23:19],post_rgb[15:10],post_rgb[7:3]};
  assign wrfifo_clr   = ~camera_init_done;
  
  
  assign rdfifo_clr  = frame_begin;
  assign disp_data   = {rdfifo_dout[15:11],3'd0,rdfifo_dout[10:5],2'd0,rdfifo_dout[4:0],3'd0};
  assign rdfifo_rden = disp_data_req;



  wire [11:0] H_Addr;
  wire [11:0] V_Addr;

  //vga output
  wire  [23:0]  disp_rgb;  //vga数据输出
  wire          disp_hs ;  //vga行同步信号
  wire          disp_vs ;  //vga场同步信号
  wire          disp_clk;  //vga像素时钟
  wire          disp_de ; //vga数据使能
	disp_driver #(
        .AHEAD_CLK_CNT ( 1 )
  )disp_driver(
		.ClkDisp		(pixelclk				),
    .Rst_n      (~g_rst_p               ),
		.Data		  	(disp_data              ),
		.DataReq		(disp_data_req	    	  ),
		.H_Addr			(H_Addr					),
		.V_Addr			(V_Addr					),
		.Disp_HS		(disp_hs				),
		.Disp_VS		(disp_vs				),
		.Disp_Red		(disp_red				),
		.Disp_Green		(disp_green				),
		.Disp_Blue		(disp_blue				),
		.Disp_Sof     (frame_begin      ),
		.Disp_DE		  (disp_de				  ),
		.Disp_PCLK		(disp_clk 				)
	);
	
	//VGA display
	assign disp_rgb = {disp_red, disp_green, disp_blue};  //VGA数据输出

  //HDMI
  dvi_encoder dvi_encoder(
    .pixelclk    (pixelclk    ),
    .pixelclk5x  (pixelclk5x  ),
    .rst_p       (g_rst_p     ),
    .blue_din    (disp_blue   ),
    .green_din   (disp_green  ),
    .red_din     (disp_red    ),
    .hsync       (disp_hs     ),
    .vsync       (disp_vs     ),
    .de          (disp_de     ),
    .tmds_clk_p  (hdmi_clk_p ),
    .tmds_clk_n  (hdmi_clk_n ),
    .tmds_data_p (hdmi_dat_p ),
    .tmds_data_n (hdmi_dat_n )
  );


  ddr3_ctrl_2port #(
    .FIFO_DW           (16  ),
    .WR_BYTE_ADDR_BEGIN (32'h0100_0000   ),
    .WR_BYTE_ADDR_END   (32'h0100_0000 + DISP_WIDTH*DISP_HEIGHT*2 -1),
    .RD_BYTE_ADDR_BEGIN (32'h0100_0000   ),
    .RD_BYTE_ADDR_END   (32'h0100_0000 + DISP_WIDTH*DISP_HEIGHT*2 -1),
    .FIFO_ADDR_DEPTH    (64  )
  )
  ddr3_ctrl_2port(
    //clock reset
    .ddr3_clk200m  (loc_clk200m   ),
    .ddr3_rst_n    (ddr3_rst_n    ),
    .ddr3_init_done(ddr3_init_done),
    //wr_fifo Interface
    .wrfifo_clr    (wrfifo_clr    ),
    .wrfifo_clk    (pclk_bufg_o   ),
    .wrfifo_wren   (wrfifo_wren   ),
    .wrfifo_din    (wrfifo_din    ),
    .wrfifo_full   (              ),
    .wrfifo_wr_cnt (              ),
    //rd_fifo Interface
    .rdfifo_clr    (rdfifo_clr    ),
    .rdfifo_clk    (pixelclk      ),
    .rdfifo_rden   (rdfifo_rden   ),
    .rdfifo_dout   (rdfifo_dout   ),
    .rdfifo_empty  (              ),
    .rdfifo_rd_cnt (              ),
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


    wire [23:0] deal_rgb;
    assign deal_rgb = {image_data[15:11],3'd0,image_data[10:5],2'd0,image_data[4:0],3'd0};
 //图像处理模块
image_process #(
    .IMG_HDISP  (DISP_WIDTH   ),
    .IMG_VDISP  (DISP_HEIGHT  )
  )
  u_image_process (
    //module clock
    .clk              (pclk_bufg_o ),           // 时钟信号
    .rst_n            (~g_rst_p    ),          // 复位信号（低有效）
    //图像处理前的数据接口
    .pre_frame_vsync  (image_data_vs   ),
    .pre_frame_href   (image_data_hs   ),
    .pre_frame_de     (image_data_valid   ),
    .pre_rgb          (deal_rgb),

    //图像处理后的数据接口
    .post_frame_vsync (post_frame_vsync ),   // 场同步信号
    .post_frame_href  (post_frame_href  ),   // 行同步信号
    .post_frame_de    (post_frame_de    ),   // 数据输入使能
    .post_rgb         (post_rgb)             // RGB颜色数据

); 


endmodule
