
module image_process #(
	parameter	[9:0]	IMG_HDISP = 10'd640,	//640*480
	parameter	[9:0]	IMG_VDISP = 10'd480
)(    
    input         clk,              //cmos 像素时钟
    input         rst_n,  
    
    //图像处理前的数据接口
    input           pre_frame_vsync,
    input           pre_frame_href ,
    input           pre_frame_de   ,
    input    [23:0] pre_rgb        ,
    
     //图像处理后的数据接口
    output          post_frame_vsync,  // 场同步信号
    output          post_frame_href ,  // 行同步信号
    output          post_frame_de   ,  // 数据输入使能
    output   [23:0] post_rgb           // RGB颜色数据
    );                            	    

//----------------------------------------------------
//第一帧图像处理 车牌定位 

//第一帧输入图像
wire			per1_frame_vsync	=	pre_frame_vsync;	            
wire			per1_frame_href	    =   pre_frame_href ;	            
wire			per1_frame_clken	=	pre_frame_de   ;	            
wire	[7:0]	per1_img_red		=	{pre_rgb[23:16]};	
wire	[7:0]	per1_img_green		=	{pre_rgb[15: 8]};		
wire	[7:0]	per1_img_blue		=	{pre_rgb[ 7: 0]};		

//定位到的车牌区域
wire [9:0] 	max_line_left ;         //车牌边框
wire [9:0] 	max_line_right;
wire [9:0] 	max_line_up   ;  
wire [9:0] 	max_line_down ;

wire [9:0] 	plate_boarder_up 	;  	//字符区域
wire [9:0] 	plate_boarder_down	; 
wire [9:0] 	plate_boarder_left 	;
wire [9:0] 	plate_boarder_right	;

//车牌定位 
VIP_Plate_Locate
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)u_VIP_Plate_Locate(
	.clk					  (clk),  			
	.rst_n					  (rst_n),

	.pre_frame_vsync		  (per1_frame_vsync),		
	.pre_frame_href		      (per1_frame_href),		    
	.pre_frame_de    		  (per1_frame_clken),		 
	.pre_rgb			      ({per1_img_red,per1_img_green,per1_img_blue}),				

	.max_line_up  			  (max_line_up  ),  			//车牌边框
	.max_line_down			  (max_line_down),
	.max_line_left 		      (max_line_left 	),  
	.max_line_right		      (max_line_right	),	
	
	.plate_boarder_up         (plate_boarder_up 	),  	//字符区域	
	.plate_boarder_down	      (plate_boarder_down	), 
	.plate_boarder_left 	  (plate_boarder_left 	),
	.plate_boarder_right	  (plate_boarder_right	) 			
	);

//----------------------------------------------------
//第二帧图像处理 字符分割

//第二帧输入图像
wire			per2_frame_vsync	=	pre_frame_vsync;	            
wire			per2_frame_href	    =	pre_frame_href;	            
wire			per2_frame_clken	=	pre_frame_de;	            
wire	[7:0]	per2_img_red		=	{pre_rgb[23:16]};

//第二帧输出图像
wire        post2_frame_vsync ;
wire        post2_frame_href	; 
wire        post2_frame_clken ;
wire        post2_img_Bit		; 

//字符坐标
wire   [20:0] 	char_boarder[7:0]	;
wire   [9:0] 	char_top 			;
wire   [9:0] 	char_down 			;

//字符分割
VIP_Char_Divide 
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)u_VIP_Char_Divide(
	.clk					  (clk),  	
	.rst_n					  (rst_n),

	.per_frame_vsync		  (per2_frame_vsync),		
	.per_frame_href		      (per2_frame_href),		    
	.per_frame_clken		  (per2_frame_clken),		 
	.per_img_red			  (per2_img_red),						

	.plate_boarder_up 	      (plate_boarder_up 	),  	
	.plate_boarder_down	      (plate_boarder_down	), 
	.plate_boarder_left 	  (plate_boarder_left 	),
	.plate_boarder_right	  (plate_boarder_right	),
	
	.post_frame_vsync		  (post2_frame_vsync	),	
	.post_frame_href		  (post2_frame_href		),		
	.post_frame_clken		  (post2_frame_clken	),	
	.post_img_Bit			  (post2_img_Bit			),
	
	.char_boarder			  (char_boarder	),
	.char_top				  (char_top		),
	.char_down				  (char_down		) 
	);
  
	
//----------------------------------------------------
//第三帧图像处理 字符识别

//第三帧输入图像
wire			per3_frame_vsync	;            
wire			per3_frame_href 	;            
wire			per3_frame_clken	;            
wire        	per3_frame_data	;	

assign per3_frame_vsync = post2_frame_vsync;
assign per3_frame_href  = post2_frame_href;
assign per3_frame_clken = post2_frame_clken;
assign per3_frame_data =  post2_img_Bit;
 
wire [7:0]	    char_index [7:0];	//匹配的字符索引
wire			match_valid		 ;	//匹配成功标志

//字符识别
VIP_Char_Recognize
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)u_VIP_Char_Recognize(
	.clk					  (clk),  	
	.rst_n					  (rst_n),	

	.per_frame_vsync		  (per3_frame_vsync),		
	.per_frame_href		      (per3_frame_href ),		    
	.per_frame_clken		  (per3_frame_clken),		 
	.per_img_Bit			  (per3_frame_data ),						
	
	.char_boarder			  (char_boarder	),
	.char_top				  (char_top		),
	.char_down				  (char_down    ),
	
	.char_index 			  (char_index ),
	.match_valid			  (match_valid)
	);

//----------------------------------------------------
//绘制车牌各方框的边界

wire			per4_frame_vsync	=	pre_frame_vsync;	            
wire			per4_frame_href	    =   pre_frame_href;	            
wire			per4_frame_clken	=	pre_frame_de;	            
wire	[7:0]	per4_img_red		=	{pre_rgb[23:16]};	
wire	[7:0]	per4_img_green		=	{pre_rgb[15: 8]};		
wire	[7:0]	per4_img_blue		=	{pre_rgb[ 7: 0]};	

wire			post4_frame_vsync	;
wire			post4_frame_href	;
wire			post4_frame_clken	;
wire	[7:0]	post4_img_red		;
wire	[7:0]	post4_img_green	    ;
wire	[7:0]	post4_img_blue	    ;

VIP_Video_add_rectangular
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)u_VIP_Video_add_rectangular
(
	//global clock
	.clk					(clk),  				 
	.rst_n					(rst_n),	
	
 	//在彩色图像上画方框          
	.per_frame_vsync		(per4_frame_vsync   ),	 
	.per_frame_href			(per4_frame_href    ),	 
    .per_frame_clken		(per4_frame_clken   ),	 
	.per_img_red			(per4_img_red	  ),		 
	.per_img_green			(per4_img_green	  ),	 
	.per_img_blue			(per4_img_blue	  ),		 

    //各边界位置
    .up_pos                (max_line_up    ),  
    .down_pos              (max_line_down  ),
	 .left_pos             (max_line_left 	),
    .right_pos             (max_line_right	),

    .char_up_pos		   (char_top ),  
    .char_down_pos	       (char_down),
	 .char_left_pos	       (plate_boarder_left ),
    .char_right_pos	       (plate_boarder_right),

	 .char_top       	   (char_top ),
    .char_down      	   (char_down),
	 .char_boarder		   (char_boarder),
	
	//Image data has been processd                 
	.post_frame_vsync		(post4_frame_vsync	), 
	.post_frame_href		(post4_frame_href	), 
	.post_frame_clken		(post4_frame_clken	), 
	.post_img_red			(post4_img_red		), 
	.post_img_green			(post4_img_green	), 
	.post_img_blue			(post4_img_blue		) 
);

//----------------------------------------------------
//绘制最终识别出来的车牌字符

wire			post5_frame_vsync	;
wire			post5_frame_href	;
wire			post5_frame_clken	;
wire	[7:0]	post5_img_red		;
wire	[7:0]	post5_img_green	    ;
wire	[7:0]	post5_img_blue	    ;

VIP_Video_add_GUI #(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)u_VIP_Video_add_GUI
(
	//global clock
	.clk					(clk),  				 
	.rst_n					(rst_n),	
	        
	.per_frame_vsync		(post4_frame_vsync	),  
	.per_frame_href			(post4_frame_href	),  
    .per_frame_clken		(post4_frame_clken	),  
	.per_img_red			(post4_img_red		),  
	.per_img_green			(post4_img_green	),  
	.per_img_blue			(post4_img_blue		), 

    //车牌字符
	.char_index 			(char_index ),
	.match_valid			(match_valid),
	
	.post_frame_vsync		(post5_frame_vsync	), 
	.post_frame_href		(post5_frame_href	), 
	.post_frame_clken		(post5_frame_clken	), 
	.post_img_red			(post5_img_red		), 
	.post_img_green			(post5_img_green	), 
	.post_img_blue			(post5_img_blue		) 
);

//----------------------------------------------------
// 输出结果 
assign	post_frame_vsync	=  post5_frame_vsync ;
assign	post_frame_href	    =  post5_frame_href  ;
assign	post_frame_de   	=  post5_frame_clken	;
assign	post_rgb    		=  {post5_img_red,post5_img_green,post5_img_blue};

endmodule