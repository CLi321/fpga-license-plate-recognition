/////////////////////////////////////////////////////////////////////////////////
// Company       : 武汉芯路恒科技有限公司
//                 http://xiaomeige.taobao.com
// Web           : http://www.corecourse.cn
// 
// Create Date   : 2019/04/10 00:00:00
// Module Name   : dvi_encoder_tb
// Description   : dvi_encoder仿真文件
// 
// Dependencies  : 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
/////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ns
`define CLK_PERIOD 20

module dvi_encoder_tb();

  reg        clk50m;
  wire       pll_locked;
  wire       pixelclk;       // system clock
  wire       pixelclk5x;     // system clock x5
  reg        rst_p;          // reset
  reg  [7:0] blue_din;       // Blue data in
  reg  [7:0] green_din;      // Green data in
  reg  [7:0] red_din;        // Red data in
  reg        hsync;          // hsync data
  reg        vsync;          // vsync data
  reg        de;             // data enable
  wire       tmds_clk_p;     //clock
  wire       tmds_clk_n;     //clock
  wire [2:0] tmds_data_p;    //rgb
  wire [2:0] tmds_data_n;    //rgb

initial clk50m = 1'b1;
always #(`CLK_PERIOD/2) clk50m = ~clk50m;

pll pll
 (
  // Clock out ports
  .clk_out1(pixelclk   ),// output clk_out1
  .clk_out2(pixelclk5x ),// output clk_out2
  // Status and control signals
  .resetn  (1'b1       ),// input resetn
  .locked  (pll_locked ),// output locked
 // Clock in ports
  .clk_in1 (clk50m     ) // input clk_in1
);

initial begin
  rst_p = 1'b1;
  blue_din = 8'd0;
  green_din = 8'd10;
  red_din = 8'd20;
  hsync = 1'b0;
  vsync = 1'b0;
  de = 1'b0;
  wait(pll_locked == 1'b1);
  #1;
  rst_p = 1'b0;
  hsync = 1'b1;
  vsync = 1'b1;
  de = 1'b1;

  repeat(20) begin
    blue_din = blue_din + 1'd1;
    green_din = green_din + 1'd1;
    red_din = red_din + 1'd1;
    @(posedge pixelclk);
    #1;
  end

  #2000;
  $stop;
end

dvi_encoder dvi_encoder(
  .pixelclk    (pixelclk   ),
  .pixelclk5x  (pixelclk5x ),
  .rst_p       (rst_p      ),
  .blue_din    (blue_din   ),
  .green_din   (green_din  ),
  .red_din     (red_din    ),
  .hsync       (hsync      ),
  .vsync       (vsync      ),
  .de          (de         ),
  .tmds_clk_p  (tmds_clk_p ),
  .tmds_clk_n  (tmds_clk_n ),
  .tmds_data_p (tmds_data_p),
  .tmds_data_n (tmds_data_n)
);

endmodule