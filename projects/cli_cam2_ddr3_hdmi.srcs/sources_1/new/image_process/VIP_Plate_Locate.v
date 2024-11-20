
//---------------------------第一部分-----------------------------
//第一部分根据蓝色，识别画面中的车牌区域，并输出边界。
//依次进行：
//  1.1 RGB转YCbCr
//  1.2 二值化
//  1.3 腐蚀
//  1.4 Sobel边缘检测
//  1.5 膨胀
//  1.6 水平投影&垂直投影-->输出车牌边界


module VIP_Plate_Locate #(
	parameter	[9:0]	IMG_HDISP = 10'd640,	//640*480
	parameter	[9:0]	IMG_VDISP = 10'd480
)
(
	//global clock
	input					clk,  							//cmos video pixel clock
	input					rst_n,							//global reset
			
	//Image data prepred to be processd			
	input					pre_frame_vsync,				//Prepared Image data vsync valid signal
	input					pre_frame_href ,				//Prepared Image data href vaild  signal
	input					pre_frame_de   ,				//Prepared Image data output/capture enable clock
    input    [23:0]         pre_rgb        ,

	output   [9:0] 	max_line_left ,  
	output   [9:0] 	max_line_right,
	output   [9:0] 	max_line_up  ,  
	output   [9:0] 	max_line_down,
	
	output   [9:0] 	plate_boarder_up 	   ,  	//车牌位置
	output   [9:0] 	plate_boarder_down	, 
	output   [9:0] 	plate_boarder_left 	,
	output   [9:0] 	plate_boarder_right	 
);


//wire define
//RGB转YCbCr
wire                  ycbcr_vsync;
wire                  ycbcr_hsync;
wire                  ycbcr_de   ;
wire   [ 7:0]         img_y      ;
wire   [ 7:0]         img_cb     ;
wire   [ 7:0]         img_cr     ;
//二值化
wire                  binarization_vsync;
wire                  binarization_hsync;
wire                  binarization_de   ;
wire                  binarization_bit  ;
//腐蚀
wire                  erosion_vsync;
wire                  erosion_hsync;
wire                  erosion_de   ;
wire                  erosion_bit  ;
//中值滤波1
wire                  median1_vsync;
wire                  median1_hsync;
wire                  median1_de   ;
wire                  median1_bit  ;
//Sobel边缘检测
wire                  sobel_vsync;
wire                  sobel_hsync;
wire                  sobel_de   ;
wire                  sobel_bit  ;
//中值滤波2
wire                  median2_vsync;
wire                  median2_hsync;
wire                  median2_de   ;
wire                  median2_bit  ;
//膨胀
wire                  dilation_vsync;
wire                  dilation_hsync;
wire                  dilation_de   ;
wire                  dilation_bit  ;
//投影
wire                  projection_vsync;
wire                  projection_hsync;
wire                  projection_de   ;
wire                  projection_bit  ;
//wire [9:0] max_line_up  ;//水平投影结果
//wire [9:0] max_line_down;
//wire [9:0] max_line_left ;//垂直投影结果
//wire [9:0] max_line_right;
////调整车牌的宽高
//wire [9:0] plate_boarder_up   ;
//wire [9:0] plate_boarder_down ;
//wire [9:0] plate_boarder_left ;
//wire [9:0] plate_boarder_right;
wire       plate_exist_flag   ;
//调整后的边框
//wire [9:0] 	plate_boarder_up 	;  	
//wire [9:0] 	plate_boarder_down	; 
//wire [9:0] 	plate_boarder_left 	;
//wire [9:0] 	plate_boarder_right	;

//--------------------------------------
//灰度转换
VIP_RGB888_YCbCr444	u_VIP_RGB888_YCbCr444
(
	//global clock
	.clk				(clk),					
	.rst_n				(rst_n),				

	//Image data prepred to be processd
	.per_frame_vsync	(pre_frame_vsync),    // vsync信号           
	.per_frame_href	    (pre_frame_href ),    // href信号            
	.per_frame_clken	(pre_frame_de   ),    // data enable信号     
	.per_img_red		(pre_rgb[23:16] ),                         
	.per_img_green		(pre_rgb[15:8 ] ),                         
	.per_img_blue		(pre_rgb[ 7:0 ] ),                         
	
	//Image data has been processd
	.post_frame_vsync	(ycbcr_vsync  ),	
	.post_frame_href	(ycbcr_hsync  ),	
	.post_frame_clken	(ycbcr_de     ), 	
	.post_img_Y			(img_y        ), 	
	.post_img_Cb		(img_cb       ), 	
	.post_img_Cr		(img_cr       )	
);

//--------------------------------------
//VIP算法--二值化
binarization u_binarization (
    .clk     (clk    ),   // 时钟信号
    .rst_n   (rst_n  ),   // 复位信号（低有效）				

	//Image data prepred to be processd
	.per_frame_vsync   (ycbcr_vsync),
	.per_frame_href    (ycbcr_hsync),	
	.per_frame_clken   (ycbcr_de   ),
	.per_img_Y         (img_cb     ),				
    
	//Image data has been processd
	.post_frame_vsync  (binarization_vsync),	
	.post_frame_href   (binarization_hsync),	
	.post_frame_clken  (binarization_de   ),	
	.post_img_Bit      (binarization_bit  ),			
	
	//二值化阈值 
	.Binary_Threshold		('d150)				
);

//--------------------------------------
//VIP算法--腐蚀
VIP_Bit_Erosion_Detector
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)u_VIP_Bit_Erosion_Detector
(
    //Global Clock
    .clk     (clk    ),   //cmos video pixel clock
    .rst_n   (rst_n  ),   //global reset

    //Image data prepred to be processd
    .per_frame_vsync   (binarization_vsync), //Prepared Image data vsync valid signal
    .per_frame_href    (binarization_hsync), //Prepared Image data href vaild  signal
    .per_frame_clken   (binarization_de   ), //Prepared Image data output/capture enable clock
    .per_img_Bit       (binarization_bit  ), //Prepared Image Bit flag outout(1: Value, 0:inValid)
    
    //Image data has been processd
    .post_frame_vsync  (erosion_vsync),    //Processed Image data vsync valid signal
    .post_frame_href   (erosion_hsync),    //Processed Image data href vaild  signal
    .post_frame_clken  (erosion_de   ),    //Processed Image data output/capture enable clock
    .post_img_Bit      (erosion_bit  )     //Processed Image Bit flag outout(1: Value, 0:inValid)
);



////中值滤波去除噪点
//VIP_Gray_Median_Filter # (
//	.IMG_HDISP(10'd640),	//640*480
//	.IMG_VDISP(10'd480)
//)u1_Gray_Median_Filter(
//	//global clock
//	.clk   (clk    ),  				//100MHz
//	.rst_n (rst_n  ),				//global reset

//	//Image data prepred to be processd
//	.per_frame_vsync   (erosion_vsync   ),	//Prepared Image data vsync valid signal
//	.per_frame_href    (erosion_hsync   ),	//Prepared Image data href vaild  signal
//	.per_frame_clken   (erosion_de      ),	//Prepared Image data output/capture enable clock
//	.per_img_Y         ({8{erosion_bit}}),	//Prepared Image brightness input
	
//	//Image data has been processd
//	.post_frame_vsync  (median1_vsync),	//Processed Image data vsync valid signal
//	.post_frame_href   (median1_hsync),	//Processed Image data href vaild  signal
//	.post_frame_clken  (median1_de   ),	//Processed Image data output/capture enable clock
//	.post_img_Y	   	   (median1_bit  )	//Processed Image brightness input
//);


//--------------------------------------
//VIP 算法--Sobel边缘检测
Sobel_Edge_Detector #(
    .SOBEL_THRESHOLD   (8'd128) //Sobel 阈值
) u_Sobel_Edge_Detector (
    //global clock
    .clk               (clk    ),              //cmos video pixel clock
    .rst_n             (rst_n  ),                //global reset
    //Image data prepred to be processd
    .per_frame_vsync  (erosion_vsync   ),    //Prepared Image data vsync valid signal
    .per_frame_href   (erosion_hsync   ),    //Prepared Image data href vaild  signal
    .per_frame_clken  (erosion_de      ),    //Prepared Image data output/capture enable clock
    .per_img_y        ({8{erosion_bit}}),    //Prepared Image brightness input  
    //Image data has been processd
    .post_frame_vsync (sobel_vsync),    //Processed Image data vsync valid signal
    .post_frame_href  (sobel_hsync),    //Processed Image data href vaild  signal
    .post_frame_clken (sobel_de   ),    //Processed Image data output/capture enable clock
    .post_img_bit     (sobel_bit  )     //Processed Image Bit flag outout(1: Value, 0 inValid)
);	


//////中值滤波去除噪点
////VIP_Gray_Median_Filter # (
////	.IMG_HDISP(10'd640),	//640*480
////	.IMG_VDISP(10'd480)
////)u2_Gray_Median_Filter(
////	//global clock
////	.clk   (clk    ),  				//100MHz
////	.rst_n (rst_n  ),				//global reset

////	//Image data prepred to be processd
////	.per_frame_vsync   (sobel_vsync   ),	//Prepared Image data vsync valid signal
////	.per_frame_href    (sobel_hsync   ),	//Prepared Image data href vaild  signal
////	.per_frame_clken   (sobel_de      ),	//Prepared Image data output/capture enable clock
////	.per_img_Y         ({8{sobel_bit}}),	//Prepared Image brightness input
	
////	//Image data has been processd
////	.post_frame_vsync  (post_frame_vsync),	//Processed Image data vsync valid signal
////	.post_frame_href   (post_frame_hsync),	//Processed Image data href vaild  signal
////	.post_frame_clken  (post_frame_de   ),	//Processed Image data output/capture enable clock
////	.post_img_Y	   	   (post_img_bit    )	//Processed Image brightness input
////);


//--------------------------------------
//VIP算法--投影前先进行线条的膨胀，防止角度偏移1到2个像素
VIP_Bit_Dilation_Detector
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)u_VIP_Bit_Dilation_Detector
(
	//global clock
	.clk   (clk    ),  				//cmos video pixel clock
	.rst_n (rst_n  ),				//global reset

	//Image data prepred to be processd
	.per_frame_vsync   (sobel_vsync   ),	//Prepared Image data vsync valid signal
	.per_frame_href    (sobel_hsync   ),	//Prepared Image data href vaild  signal
	.per_frame_clken   (sobel_de      ),	//Prepared Image data output/capture enable clock
	.per_img_Bit       (sobel_bit     ),	//Prepared Image Bit flag outout(1: Value, 0:inValid)
	
	//Image data has been processd
	.post_frame_vsync  (dilation_vsync),	//Processed Image data vsync valid signal
	.post_frame_href   (dilation_hsync),	//Processed Image data href vaild  signal
	.post_frame_clken  (dilation_de   ),	//Processed Image data output/capture enable clock
	.post_img_Bit  	   (dilation_bit  )     //Processed Image Bit flag outout(1: Value, 0:inValid)	
);

//--------------------------------------
//VIP算法--对整帧图像进行水平投影
VIP_horizon_projection
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP),
	.EDGE_THROD	(100)			//边缘阈值
)u_VIP_horizon_projection
(
	//global clock
	.clk   (clk    ),  				//cmos video pixel clock
	.rst_n (rst_n  ),				//global reset

	//Image data prepred to be processd
	.per_frame_vsync   (dilation_vsync),  //Prepared Image data vsync valid signal
	.per_frame_href    (dilation_hsync),  //Prepared Image data href vaild  signal
	.per_frame_clken   (dilation_de   ),  //Prepared Image data output/capture enable clock
	.per_img_Bit       (dilation_bit  ),  //Prepared Image Bit flag outout(1: Value, 0:inValid)	

    .max_line_up    (max_line_up  ),      //边沿坐标
    .max_line_down  (max_line_down),
	
    .horizon_start  ('d10 ),             //投影起始列
    .horizon_end    (IMG_HDISP - 'd10)   //投影结束列  
);

//--------------------------------------
//VIP算法--对整帧图像进行竖直投影
VIP_vertical_projection
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP),
	.EDGE_THROD	(45)				//边缘阈值
)u_VIP_vertical_projection
(
	//global clock
	.clk   (clk    ),//cmos video pixel clock
	.rst_n (rst_n  ),//global reset

	//Image data prepred to be processd
	.per_frame_vsync   (dilation_vsync),  //Prepared Image data vsync valid signal
	.per_frame_href    (dilation_hsync),  //Prepared Image data href vaild  signal
	.per_frame_clken   (dilation_de   ),  //Prepared Image data output/capture enable clock
	.per_img_Bit       (dilation_bit  ),  //Prepared Image Bit flag outout(1: Value, 0:inValid)	

    .max_line_left     (max_line_left ),	   //边沿坐标
    .max_line_right    (max_line_right),
	   
    .vertical_start    ('d10 ),               //投影起始行
    .vertical_end      (IMG_VDISP - 'd10)     //投影结束行	   
);



//-------------------------------------
//修正车牌的边界，使其只包含字符区域
plate_boarder_adjust u_plate_boarder_adjust(
	//global clock
	.clk   (clk    ),  				//cmos video pixel clock
	.rst_n (rst_n  ),				//global reset		

	//Image data prepred to be processd
	.per_frame_vsync		(dilation_vsync),	

	.max_line_up  			(max_line_up  ),  
	.max_line_down		 	(max_line_down),
	.max_line_left 		    (max_line_left 	),  
	.max_line_right		    (max_line_right	),
	
   .plate_boarder_up		(plate_boarder_up 	),
   .plate_boarder_down	    (plate_boarder_down	),
   .plate_boarder_left	    (plate_boarder_left ),
   .plate_boarder_right	    (plate_boarder_right),

   .plate_exist_flag	    ()	
);


/*	
	assign  plate_boarder_up    = max_line_up;
	assign  plate_boarder_down  = max_line_down;
	assign  plate_boarder_left 	= max_line_left;
	assign  plate_boarder_right	= max_line_right;
*/


endmodule
