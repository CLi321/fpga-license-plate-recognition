
/////////////////////////////////////////////////////////////////////////////////
// Company       : 武汉芯路恒科技有限公司
//                 http://xiaomeige.taobao.com
// Web           : http://www.corecourse.cn
// 
// Create Date   : 2019/05/01 00:00:00
// Module Name   : sim_dat_gen
// Description   : 仿真测试数据产生模块
// 
// Dependencies  : 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
/////////////////////////////////////////////////////////////////////////////////

module sim_dat_gen #(
  parameter DISP_WIDTH  = 800,
  parameter DISP_HEIGHT = 480,
  parameter DATA_WIDTH  = 16
)
(
  input                  clk,
  input                  reset,
  input                  gen_en,
  output [DATA_WIDTH-1:0]sim_dat,
  output                 sim_dat_vaild
);

  reg [15:0]col_data_cnt;
  reg [15:0]row_data_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset)
      col_data_cnt <= 16'd0;
    else if(!gen_en)
      col_data_cnt <= 16'd0;
    else if(col_data_cnt == DISP_WIDTH)
      col_data_cnt <= 16'd0;
    else
      col_data_cnt <= col_data_cnt + 1'b1;
  end

  always@(posedge clk or posedge reset)
  begin
    if(reset)
      row_data_cnt <= 16'd0;
    else if(col_data_cnt == DISP_WIDTH)
      if(row_data_cnt >= DISP_HEIGHT-1)
        row_data_cnt <= 16'd0;
      else
        row_data_cnt <= row_data_cnt + 1'b1;
    else
      row_data_cnt <= row_data_cnt;
  end

  assign sim_dat = row_data_cnt;
  assign sim_dat_vaild = (col_data_cnt > 1'b0) && (col_data_cnt <= DISP_WIDTH) && (row_data_cnt <= DISP_HEIGHT-1);

endmodule