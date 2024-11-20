
//---------------------------第三部分-----------------------------
//第三部分根据第二部分给出的每个字符的边界，进行模板匹配。
//依次进行：
//  3.1 提取特征值
//  3.2 模板匹配
//  3.3 添加边框
//  3.4 添加字符

module VIP_Char_Recognize #(
	parameter	[9:0]	IMG_HDISP = 10'd640,	//640*480
	parameter	[9:0]	IMG_VDISP = 10'd480
)
(
	//global clock
	input					clk,  							//cmos video pixel clock
	input					rst_n,							//global reset
			
	//Image data prepred to be processd			
	input					per_frame_vsync,				//Prepared Image data vsync valid signal
	input					per_frame_href,				   //Prepared Image data href vaild  signal
	input					per_frame_clken,				//Prepared Image data output/capture enable clock
	input		  			per_img_Bit,					//Prepared Image red data to be processed
	
	input   [20:0]   	char_boarder[7:0],
    input   [9:0] 		char_top ,
    input   [9:0] 		char_down, 	

    output   [7:0]	    char_index [7:0],				//匹配的字符索引
    output  			match_valid		 				//匹配成功标志
);

//--------------------------------------
//VIP算法--特征识别
	
wire [0:4] 	char_feature  [7:0] [7:0] ;		//特征结果
//wire [4:0] 	char_feature  [7:0] [0:7] ;		//特征结果
wire 			char_feature_valid;

plate_feature_recognize
#(
	.IMG_HDISP	(IMG_HDISP),	//640*480
	.IMG_VDISP	(IMG_VDISP)
)u_plate_feature_recognize
(
	//global clock
    .clk             (clk       ),   // 时钟信号
    .rst_n           (rst_n     ),   // 复位信号（低有效）				

	//Image data prepred to be processd
	.per_frame_vsync		(per_frame_vsync	),	
	.per_frame_href		    (per_frame_href	    ),		
	.per_frame_clken		(per_frame_clken	),	
	.per_img_Bit			(per_img_Bit		),		

	.char_boarder			(char_boarder ),
	.char_top       		(char_top     ),
    .char_down      		(char_down    ),
	
	.char_feature			(char_feature ),
    .char_feature_valid	    (char_feature_valid) 
);

//--------------------------------------
//VIP算法--卷积模板匹配

//wire [7:0]	char_index [7:0];	//匹配的字符索引
//wire			match_valid		 ;	//匹配成功标志

conv_template_match conv_template_match(
    .clk                    (clk       ),   // 时钟信号
    .rst_n                  (rst_n     ),   // 复位信号（低有效）
	
	.char_feature			(char_feature),
    .char_feature_valid	    (char_feature_valid), 
	
	.char_index 			(char_index ),
	.match_valid			(match_valid)
);


endmodule 
