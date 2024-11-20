module VIP_Video_add_rectangular#(
	parameter	[9:0]	IMG_HDISP = 10'd640,	//640*480
	parameter	[9:0]	IMG_VDISP = 10'd480
)(
	//global clock
	input				clk,  				 
	input				rst_n,				 
                                             
	//Image data prepred to be processd      
	input				per_frame_vsync,	 
	input				per_frame_href ,	 
	input				per_frame_clken,	 
	input		[7:0]	per_img_red		,		 
	input		[7:0]	per_img_green	,		 
	input		[7:0]	per_img_blue	,		 
                                             
    input     	[9:0]  	left_pos  ,            		//整个车牌的位置	
    input     	[9:0]  	right_pos ,
    input     	[9:0]  	up_pos ,  	
    input     	[9:0]  	down_pos,
	
    input     	[9:0]  	char_left_pos  ,            		//字符区域的位置	
    input     	[9:0]  	char_right_pos ,
    input     	[9:0]  	char_up_pos ,  	
    input     	[9:0]  	char_down_pos,

	input       [20:0] 	char_boarder[7:0],			//车牌中字符的位置
    input     	[9:0]  	char_top	,  	
    input     	[9:0]  	char_down ,
                                             
	//Image data has been processd           
	output reg			post_frame_vsync,	 
	output reg			post_frame_href ,	 
	output reg			post_frame_clken,	 
	output reg 	[7:0]	post_img_red	,		 
	output reg 	[7:0]	post_img_green	,		 
	output reg 	[7:0]	post_img_blue	  	
);

               

localparam BLACK  = 16'b00000_000000_00000;     //RGB565 
localparam WHITE  = 16'b11111_111111_11111;     //RGB565 
localparam RED    = 16'b11111_000000_00000;     //RGB565 
localparam BLUE   = 16'b00000_000000_11111;     //RGB565 
localparam GREEN  = 16'b00000_111111_00000;     //RGB565 
localparam GRAY   = 16'b11000_110000_11000;     //RGB565 

//------------------------------------------
reg [9:0]  	x_cnt;
reg [9:0]   y_cnt;

//对输入的像素进行 行/场 方向计数，得到其纵横坐标。
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
			x_cnt <= 10'd0;
			y_cnt <= 10'd0;
		end
	else
		if(!per_frame_vsync)begin
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
reg border_flag;

//绘制一个大的方框，标记整个车牌

//判断坐标是否落在矩形方框边界上
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin	//初始化
			border_flag <= 0;
		end
    else begin

            //判断上下边界
            if((x_cnt >  left_pos) && (x_cnt < right_pos) && ((y_cnt == up_pos) ||(y_cnt == down_pos)) )  
				border_flag <= 1;
           //判断左右边界
            else if((y_cnt > up_pos) && (y_cnt < down_pos) && ((x_cnt == left_pos) ||(x_cnt == right_pos)) )     
				border_flag <= 1;
            
			//字符上下边界
			else if((x_cnt >  char_left_pos) && (x_cnt < char_right_pos) && ((y_cnt == char_up_pos) ||(y_cnt == char_down_pos)) )  
				border_flag <= 1;
           //字符左右边界
            else if((y_cnt > char_up_pos) && (y_cnt < char_down_pos) && ((x_cnt == char_left_pos) ||(x_cnt == char_right_pos)) )     
				border_flag <= 1;
			
			else 
                border_flag <= 0;

    end 
end 

//------------------------------------------
//绘制字符边框
wire [7:0] char_flag;			    //各字符的有效标志
wire [9:0] char_left 	[7:0] ;		//各字符的左/右/上/下边界
wire [9:0] char_right 	[7:0] ;

wire [9:0] char_width 	[7:0] ;
wire [9:0] char_height = char_down - char_top	 ;

generate
genvar i;
	for(i=0; i<8; i = i+1) begin :  CHAR_POS
		assign char_flag[i]		= char_boarder[i][20];
		assign char_left[i]		= char_boarder[i][19:10];
		assign char_right[i] 	= char_boarder[i][ 9: 0];
				
		assign char_width[i] 	= char_boarder[i][ 9: 0] - char_boarder[i][19:10];
	end
endgenerate

//给每个字符绘制小的边框
integer j;
reg [7:0] char_border_flag;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 	//初始化
			char_border_flag <= 8'd0;
    else begin
        for(j=0; j<8; j = j+1) begin	 
            //判断上下边界
            if((x_cnt >  char_left[j]) && (x_cnt < char_right[j]) && ((y_cnt == char_top) ||(y_cnt == char_down)) )  
				char_border_flag[j] <= char_flag[j];

           //判断左右边界
            else if((y_cnt > char_top) && (y_cnt < char_down) && ((x_cnt == char_left[j]) ||(x_cnt == char_right[j])) )     
				char_border_flag[j] <= char_flag[j];

            else 
                char_border_flag[j] <= 1'b0;	
        end
    end 
end

//------------------------------------------
//将每个字符的边框再次划分8*5的小方框

reg [7:0] div_width  [7:0];
reg [7:0] div_height [7:0];

integer k;
always @(posedge clk) begin
	for(k=0;k<8;k=k+1) begin
		if(char_width[k] % 5 > 2)
			div_width[k]  <= (char_width[k] / 5) + 1;
		else
			div_width[k]  <= (char_width[k] / 5);
		
		if(char_height % 8 > 3)
			div_height[k] <= (char_height / 8) + 1;
		else
			div_height[k] <= (char_height / 8);
	end
end

integer m;
reg [7:0] div_border_flag;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 	//初始化
			div_border_flag <= 8'd0;
    else begin
        for(m=0; m<8; m = m+1) begin	 
            //判断上下边界
            if((x_cnt >  char_left[m]) && (x_cnt < char_right[m]) && (y_cnt > char_top) && (y_cnt < char_down) )  begin
				if(((x_cnt-char_left[m])%div_width[m] == 0) || ((y_cnt-char_top)%div_height[m] == 0))
					div_border_flag[m] <= char_flag[m];
				else
					div_border_flag[m] <= 1'b0;
			end
			else 
                div_border_flag[m] <= 1'b0;
        end
    end 
end

wire div_border_flag_final;

assign div_border_flag_final = (div_border_flag > 8'd0)? 1'b1 : 1'b0;
    

//像素点落在任一矩形框上均会导致char_border_flag不为0
assign char_border_flag_final = (char_border_flag > 8'd0)? 1'b1 : 1'b0;


assign VGA_R = border_flag ? 4'b1111 : (char_border_flag_final ? 4'b0000 : (div_border_flag_final ? 4'b0000 : 4'b0000));
assign VGA_G = border_flag ? 4'b0000 : (char_border_flag_final ? 4'b1111 : (div_border_flag_final ? 4'b0000 : 4'b0000));
assign VGA_B = border_flag ? 4'b0000 : (char_border_flag_final ? 4'b0000 : (div_border_flag_final ? 4'b1111 : 4'b0000));


//------------------------------------------
//lag 2 clocks signal sync  
reg			per_frame_vsync_r;
reg			per_frame_href_r ;	
reg			per_frame_clken_r;
reg	[7:0]	per_img_red_r	 ;		 
reg	[7:0]	per_img_green_r	 ;		 
reg	[7:0]	per_img_blue_r	 ;	


always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		per_frame_vsync_r 	<= 0;
		per_frame_href_r 	<= 0;
		per_frame_clken_r 	<= 0;
		
		per_img_red_r	 	<= 0;
		per_img_green_r	 	<= 0;
		per_img_blue_r	 	<= 0;
		
		post_frame_vsync 	<= 0;
		post_frame_href 	<= 0;
		post_frame_clken 	<= 0;			
		end
	else
		begin
		per_frame_vsync_r 	<= 	per_frame_vsync		;
		per_frame_href_r	<= 	per_frame_href		;
		per_frame_clken_r 	<= 	per_frame_clken		;
		
		per_img_red_r	 	<=  per_img_red		;
		per_img_green_r	 	<=  per_img_green	;
		per_img_blue_r	 	<=  per_img_blue	;
		
		post_frame_vsync 	<= 	per_frame_vsync_r 	;
		post_frame_href 	<= 	per_frame_href_r	;
		post_frame_clken 	<= 	per_frame_clken_r 	;
		
		post_img_red	 	<=  border_flag ? 8'hff : (char_border_flag_final ? 8'h00 : (div_border_flag_final ? 8'h00 : per_img_red_r));
		post_img_green	 	<=  border_flag ? 8'h00 : (char_border_flag_final ? 8'hff : (div_border_flag_final ? 8'h00 : per_img_green_r));
		post_img_blue	 	<=  border_flag ? 8'h00 : (char_border_flag_final ? 8'h00 : (div_border_flag_final ? 8'hff : per_img_blue_r));
		end
end

endmodule 