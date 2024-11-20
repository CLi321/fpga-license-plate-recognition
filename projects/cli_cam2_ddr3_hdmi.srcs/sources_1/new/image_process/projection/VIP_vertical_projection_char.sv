`timescale 1ns/1ns
module VIP_vertical_projection_char
#(
	parameter	[9:0]	IMG_HDISP = 10'd640,	//640*480
	parameter	[9:0]	IMG_VDISP = 10'd480
)
(
	//global clock
	input				clk,  				//cmos video pixel clock
	input				rst_n,				//global reset

	//Image data prepred to be processd
	input				per_frame_vsync,	//Prepared Image data vsync valid signal
	input				per_frame_href,		//Prepared Image data href vaild  signal
	input				per_frame_clken,	//Prepared Image data output/capture enable clock
	input				per_img_Bit,		//Prepared Image Bit flag outout(1: Value, 0:inValid)
	
	//Image data has been processd
	output				post_frame_vsync,	//Processed Image data vsync valid signal
	output				post_frame_href,	//Processed Image data href vaild  signal
	output				post_frame_clken,	//Processed Image data output/capture enable clock
	output				post_img_Bit, 		//Processed Image Bit flag outout(1: Value, 0:inValid)

	output reg [20:0] 	char_boarder[7:0],  //{valid_flag[0],left_boarder[9:0],right_boarder[9:0]}
	
    input      [9:0] 	vertical_start,		//ͶӰ��ʼ��
    input      [9:0] 	vertical_end,		//ͶӰ������	

    input       [9:0] 	plate_boarder_left 	,
    input       [9:0] 	plate_boarder_right	 	
);

reg [9:0] 	max_line_left ;		//��������
reg [9:0] 	max_line_right;

reg			per_frame_vsync_r;
reg			per_frame_href_r;	
reg			per_frame_clken_r;
reg  		per_img_Bit_r;

reg			per_frame_vsync_r2;
reg			per_frame_href_r2;	
reg			per_frame_clken_r2;
reg         per_img_Bit_r2;

assign	post_frame_vsync 	= 	per_frame_vsync_r2;
assign	post_frame_href 	= 	per_frame_href_r2;	
assign	post_frame_clken 	= 	per_frame_clken_r2;
assign  post_img_Bit     	=   per_img_Bit_r2;

//------------------------------------------
//lag 1 clocks signal sync  

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		per_frame_vsync_r2 	<= 0;
		per_frame_href_r2 	<= 0;
		per_frame_clken_r2 	<= 0;
		per_img_Bit_r2		<= 0;
		end
	else
		begin
		per_frame_vsync_r2 	<= 	per_frame_vsync_r 	;
		per_frame_href_r2	<= 	per_frame_href_r 	;
		per_frame_clken_r2 	<= 	per_frame_clken_r 	;
		per_img_Bit_r2		<= 	per_img_Bit_r		;
		end
end

//------------------------------------------
//lag 1 clocks signal sync  

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		per_frame_vsync_r 	<= 0;
		per_frame_href_r 	<= 0;
		per_frame_clken_r 	<= 0;
		per_img_Bit_r		<= 0;
		end
	else
		begin
		per_frame_vsync_r 	<= 	per_frame_vsync	;
		per_frame_href_r	<= 	per_frame_href	;
		per_frame_clken_r 	<= 	per_frame_clken	;
		per_img_Bit_r	    <= 	per_img_Bit		;
		end
end

wire vsync_pos_flag;
wire vsync_neg_flag;

assign vsync_pos_flag = per_frame_vsync    & (~per_frame_vsync_r);
assign vsync_neg_flag = (~per_frame_vsync) & per_frame_vsync_r;

//------------------------------------------
//����������ؽ��С���/��������������õ����ݺ�����
reg [9:0]  	x_cnt;
reg [9:0]   y_cnt;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			x_cnt <= 10'd0;
			y_cnt <= 10'd0;
		end
	else
		if(vsync_pos_flag)begin
			x_cnt <= 10'd0;
			y_cnt <= 10'd0;
		end
		else if(per_frame_clken) begin
			if(x_cnt < IMG_HDISP - 1) begin
				x_cnt <= x_cnt + 1'b1;
				y_cnt <= y_cnt;
			end
			else begin
				x_cnt <= 10'd0;
				y_cnt <= y_cnt + 1'b1;
			end
		end
end

//------------------------------------------
//�Ĵ桰��/�����������
reg [9:0]  	x_cnt_r;
reg [9:0]   y_cnt_r;

always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			x_cnt_r <= 10'd0;
			y_cnt_r <= 10'd0;
		end
	else begin
			x_cnt_r <= x_cnt;
            y_cnt_r <= y_cnt;
		end
end

//------------------------------------------
//��ֱ����ͶӰ
reg  		ram_wr;
wire [9:0] 	ram_wr_data;
wire [9:0] 	ram_rd_data;

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        ram_wr <= 1'b0;
    end
    else if(per_frame_clken)
        ram_wr <= 1'b1;
    else
        ram_wr <= 1'b0;
end

//����֡����ͶӰ
// assign ram_wr_data = (y_cnt == 10'd0) ? 10'd0 : 					//��һ�У���ʼ��RAMΪ0
//                         per_img_Bit_r ? ram_rd_data + 1'b1 :
//                             ram_rd_data;

//��ָ��������֮�����ͶӰ

assign ram_wr_data = (y_cnt == 10'd0) ? 10'd0 : 					//��һ�У���ʼ��RAMΪ0
                        ((y_cnt > vertical_start) && (y_cnt < vertical_end)) ? (ram_rd_data + per_img_Bit_r) :  
                            ram_rd_data;

projection_ram	u_projection_ram (
  .clka  (clk           ),// input wire clka
  .wea   (ram_wr        ),// input wire [0 : 0] wea
  .addra (x_cnt_r       ),// input wire [9 : 0] addra
  .dina  (ram_wr_data   ),// input wire [9 : 0] dina
  
  .clkb  (clk           ),// input wire clkb
  .addrb (x_cnt         ),// input wire [9 : 0] addrb
  .doutb (ram_rd_data   ) // output wire [9 : 0] doutb
	);

	
reg [9:0] rd_data_d1;
reg [9:0] rd_data_d2;
reg [9:0] rd_data_d3;

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rd_data_d1 <= 10'd0;
        rd_data_d2 <= 10'd0;
    end
    else if(per_frame_clken) begin
        rd_data_d1 <= ram_rd_data;
        rd_data_d2 <= rd_data_d1;
        rd_data_d3 <= rd_data_d2;
	end
end

//���㳵�ƿ��
wire [9:0] plate_width;
assign plate_width = plate_boarder_right - plate_boarder_left;


reg [2:0] char_cnt	;
reg [20:0] char_boarder_reg[7:0];

integer i;

//����RAM��ͳ�Ƶ�ͶӰ������ж��ַ��߽�
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		char_cnt <= 3'd0;
		
		for(i=0;i<8; i++) begin
			char_boarder_reg[i] <= 31'd0;	//��ʼ������б�	
		end
		
    end
    else if(per_frame_clken) begin

        if(y_cnt == IMG_VDISP - 1'b1) begin    
		
			if((rd_data_d1 == 10'd0) && (ram_rd_data > 10'd0)) begin //������
				
				if(char_cnt == 3'd1) begin										//�Դ����ֽ��������ж�
					if(x_cnt_r - char_boarder_reg[0][19:10] < plate_width[9:3])	//�ڶ���������С�ں��ֿ�ȣ����µ��ڳ��Ƴߴ��1/8�������϶�Ϊ���ҽṹ�ĺ���
						char_cnt <= 3'd0;   									//��ʱ���Եڶ��������أ�ͬʱ����������0�����������ڵڶ����½��ص���ʱ�����¸��º��ֵ��ұ߽�
					else
						char_boarder_reg[char_cnt][19:10] <= x_cnt_r - 1;		//��߽�
				end 

				else begin
					char_boarder_reg[char_cnt][19:10] <= x_cnt_r - 1;			//��߽�
				end
			end	
			
			if((rd_data_d1 > 10'd0) && (ram_rd_data == 10'd0)) begin //�½���

				char_boarder_reg[char_cnt][9:0] <= x_cnt_r;						//�ұ߽�
				char_boarder_reg[char_cnt][20]  <= 1'b1;						//��Ч��־λ
			
				if(char_cnt != 3'd2) begin										//���ַ��Ŀ�Ƚ����жϣ����С��һ������ֵ������Ϊ�ǳ����ϵ��۵�
					if(x_cnt_r - char_boarder_reg[char_cnt][19:10] < 3)
						char_cnt <= char_cnt;									//���µȴ��µ�������/�½���
					else 
						char_cnt <= char_cnt + 1'b1;
				end
				else
					char_cnt <= char_cnt + 1'b1;
			end		
        end
	end
	else if(vsync_pos_flag) begin
		for(i=0;i<8; i++) begin
			char_boarder_reg[i] <= 31'd0;	//��ʼ������б�	
		end
		
		char_cnt <= 3'd0;
	end
end

//�Ĵ�������
integer j;

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
		for(j=0;j<8; j++) begin
			char_boarder[j] <= 31'd0;	//��ʼ������б�	
		end
    end
    else if(vsync_neg_flag) begin
		for(j=0;j<8; j++) begin
			char_boarder[j] <= char_boarder_reg[j];	//��ʼ������б�	
		end
    end   
end

endmodule
