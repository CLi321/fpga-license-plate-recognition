
//---------------------------�ڶ�����-----------------------------
//�ڶ��������õ�һ������ȡ�ĳ��Ʊ߽磬��ȡ�߽���ÿ���ַ�������
//���ν��У�
//  2.1 ��ֵ��
//  2.2 ��ʴ
//  2.3 ����
//  2.4 ˮƽͶӰ&��ֱͶӰ-->��������ַ��ı߽�

module VIP_Char_Divide #(
	parameter	[9:0]	IMG_HDISP = 10'd640,	//640*480
	parameter	[9:0]	IMG_VDISP = 10'd480
)
(
	//global clock
	input					clk,  							//cmos video pixel clock
	input					rst_n,							//global reset
			
	//Image data prepred to be processd			
	input					per_frame_vsync,				//Prepared Image data vsync valid signal
	input					per_frame_href,				//Prepared Image data href vaild  signal
	input					per_frame_clken,				//Prepared Image data output/capture enable clock
	input		[7:0]		per_img_red,					//Prepared Image red data to be processed

	output				post_frame_vsync,				//Processed Image data vsync valid signal
	output				post_frame_href,				//Processed Image data href vaild  signal
	output				post_frame_clken,				//Processed Image data output/capture enable clock
	output				post_img_Bit, 					//Processed Image Bit flag outout(1: Value, 0:inValid)

	input    [9:0] 	    plate_boarder_up 	,  	//����λ��
	input    [9:0] 	    plate_boarder_down	, 
	input    [9:0] 	    plate_boarder_left 	,
	input    [9:0] 	    plate_boarder_right	,
	
	output   [20:0] 	char_boarder[7:0],
    output   [9:0] 	    char_top ,
    output   [9:0] 	    char_down 	
);

//-----------------�ڶ�����-----------------
//�ַ���ֵ��
wire                  char_bin_vsync;
wire                  char_bin_hsync;
wire                  char_bin_de   ;
wire                  char_bin_bit  ;
//��ʴ
wire                  char_ero_vsync;
wire                  char_ero_hsync;
wire                  char_ero_de   ;
wire                  char_ero_bit  ;
//����
wire                  char_dila_vsync;
wire                  char_dila_hsync;
wire                  char_dila_de   ;
wire                  char_dila_bit  ;
//ͶӰ
wire char_proj_vsync;
wire char_proj_hsync;
wire char_proj_de   ;
wire char_proj_bit  ;



//wire [20:0] 	char_boarder[7:0];
	
//wire [9:0] 	char_top  ;
//wire [9:0] 	char_down;
	
//--------------------------------------
//VIP�㷨--���ַ�������ж�ֵ��
binarization_char 
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)u_binarization_char (
    .clk             (clk       ),   // ʱ���ź�
    .rst_n           (rst_n     ),   // ��λ�źţ�����Ч��				

	//Image data prepred to be processd
	.per_frame_vsync			(per_frame_vsync),		
	.per_frame_href			    (per_frame_href),		
	.per_frame_clken			(per_frame_clken),		
	.per_img_Y					(per_img_red),			
    
	//Image data has been processd
	.post_frame_vsync			(char_bin_vsync	),
	.post_frame_href			(char_bin_hsync	),	
	.post_frame_clken			(char_bin_de    ),
	.post_img_Bit				(char_bin_bit  	),	
		
	//��ֵ����ֵ 	
	.Binary_Threshold			(128),

   .plate_boarder_up 		(plate_boarder_up 	),
   .plate_boarder_down		(plate_boarder_down	),

   .plate_boarder_left 		(plate_boarder_left ),
   .plate_boarder_right		(plate_boarder_right) 
);

//--------------------------------------
//VIP�㷨--��ʴ
VIP_Bit_Erosion_Detector
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)u_VIP_Bit_Erosion_Detector_red
(
    //Global Clock
    .clk     (clk    ),   //cmos video pixel clock
    .rst_n   (rst_n  ),   //global reset

    //Image data prepred to be processd
    .per_frame_vsync   (char_bin_vsync), //Prepared Image data vsync valid signal
    .per_frame_href    (char_bin_hsync), //Prepared Image data href vaild  signal
    .per_frame_clken   (char_bin_de   ), //Prepared Image data output/capture enable clock
    .per_img_Bit       (char_bin_bit  ), //Prepared Image Bit flag outout(1: Value, 0:inValid)
    
    //Image data has been processd
    .post_frame_vsync  (char_ero_vsync),    //Processed Image data vsync valid signal
    .post_frame_href   (char_ero_hsync),    //Processed Image data href vaild  signal
    .post_frame_clken  (char_ero_de   ),    //Processed Image data output/capture enable clock
    .post_img_Bit      (char_ero_bit  )     //Processed Image Bit flag outout(1: Value, 0:inValid)
);

//--------------------------------------
//VIP�㷨--����
VIP_Bit_Dilation_Detector
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)u_VIP_Bit_Dilation_Detector_red
(
	//global clock
	.clk   (clk    ),  				//cmos video pixel clock
	.rst_n (rst_n  ),				//global reset

	//Image data prepred to be processd
	.per_frame_vsync   (char_ero_vsync ),	//Prepared Image data vsync valid signal
	.per_frame_href    (char_ero_hsync ),	//Prepared Image data href vaild  signal
	.per_frame_clken   (char_ero_de    ),	//Prepared Image data output/capture enable clock
	.per_img_Bit       (char_ero_bit   ),	//Prepared Image Bit flag outout(1: Value, 0:inValid)
	
	//Image data has been processd
	.post_frame_vsync  (char_dila_vsync),	//Processed Image data vsync valid signal
	.post_frame_href   (char_dila_hsync),	//Processed Image data href vaild  signal
	.post_frame_clken  (char_dila_de   ),	//Processed Image data output/capture enable clock
	.post_img_Bit  	   (char_dila_bit  )   //Processed Image Bit flag outout(1: Value, 0:inValid)
);

//--------------------------------------
//VIP�㷨--�ַ����������ֱͶӰ
VIP_vertical_projection_char
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)u_VIP_vertical_projection_char
(
	//global clock
	.clk   (clk         ),  			//cmos video pixel clock
	.rst_n (rst_n       ),				//global reset			

	//Image data prepred to be processd
	.per_frame_vsync		(char_dila_vsync),	
	.per_frame_href		    (char_dila_hsync),		
	.per_frame_clken		(char_dila_de   ),	
	.per_img_Bit			(char_dila_bit  ),		

	//Image data has been processd
	.post_frame_vsync		(post_frame_vsync	),	
	.post_frame_href		(post_frame_href	),		
	.post_frame_clken		(post_frame_clken	),	
	.post_img_Bit			(post_img_Bit		),

	.char_boarder			(char_boarder),
	
	.vertical_start		    ('d10), 							//���Ʒ�Χ����������У��Ѿ��ڶ�ֵ����ʱ�򱻹��˵���
	.vertical_end			(IMG_VDISP - 'd10),
	
   .plate_boarder_left	(plate_boarder_left ),  //���ƺ������꣬�����ų���һ������Ϊ���ҽṹʱ������ʶ��������ַ�
   .plate_boarder_right	(plate_boarder_right) 	
);

//--------------------------------------
//VIP�㷨--�ַ��������ˮƽͶӰ
VIP_horizon_projection_char
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP),
	.EDGE_THROD	(14)			   //���ر仯����7*2�Σ���ʾ����߽�λ��
)u_VIP_horizon_projection_char
(
	//global clock
	.clk   (clk         ),  			//cmos video pixel clock
	.rst_n (rst_n       ),				//global reset			

	//Image data prepred to be processd
	.per_frame_vsync		(char_dila_vsync),	
	.per_frame_href		    (char_dila_hsync),		
	.per_frame_clken		(char_dila_de   ),	
	.per_img_Bit			(char_dila_bit  ),			

	.char_top 				(char_top ),
	.char_down				(char_down),
                             
	.horizon_start			('d10), 								//���Ʒ�Χ����������У��Ѿ��ڶ�ֵ����ʱ�򱻹��˵���
	.horizon_end			(IMG_HDISP - 'd10)
);
 
endmodule 