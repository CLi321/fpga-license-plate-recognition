
module image_process #(
	parameter	[9:0]	IMG_HDISP = 10'd640,	//640*480
	parameter	[9:0]	IMG_VDISP = 10'd480
)(    
    input         clk,              //cmos ����ʱ��
    input         rst_n,  
    
    //ͼ����ǰ�����ݽӿ�
    input           pre_frame_vsync,
    input           pre_frame_href ,
    input           pre_frame_de   ,
    input    [23:0] pre_rgb        ,
    
     //ͼ���������ݽӿ�
    output          post_frame_vsync,  // ��ͬ���ź�
    output          post_frame_href ,  // ��ͬ���ź�
    output          post_frame_de   ,  // ��������ʹ��
    output   [23:0] post_rgb           // RGB��ɫ����
    );                            	    

//----------------------------------------------------
//��һ֡ͼ���� ���ƶ�λ 

//��һ֡����ͼ��
wire			per1_frame_vsync	=	pre_frame_vsync;	            
wire			per1_frame_href	    =   pre_frame_href ;	            
wire			per1_frame_clken	=	pre_frame_de   ;	            
wire	[7:0]	per1_img_red		=	{pre_rgb[23:16]};	
wire	[7:0]	per1_img_green		=	{pre_rgb[15: 8]};		
wire	[7:0]	per1_img_blue		=	{pre_rgb[ 7: 0]};		

//��λ���ĳ�������
wire [9:0] 	max_line_left ;         //���Ʊ߿�
wire [9:0] 	max_line_right;
wire [9:0] 	max_line_up   ;  
wire [9:0] 	max_line_down ;

wire [9:0] 	plate_boarder_up 	;  	//�ַ�����
wire [9:0] 	plate_boarder_down	; 
wire [9:0] 	plate_boarder_left 	;
wire [9:0] 	plate_boarder_right	;

//���ƶ�λ 
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

	.max_line_up  			  (max_line_up  ),  			//���Ʊ߿�
	.max_line_down			  (max_line_down),
	.max_line_left 		      (max_line_left 	),  
	.max_line_right		      (max_line_right	),	
	
	.plate_boarder_up         (plate_boarder_up 	),  	//�ַ�����	
	.plate_boarder_down	      (plate_boarder_down	), 
	.plate_boarder_left 	  (plate_boarder_left 	),
	.plate_boarder_right	  (plate_boarder_right	) 			
	);

//----------------------------------------------------
//�ڶ�֡ͼ���� �ַ��ָ�

//�ڶ�֡����ͼ��
wire			per2_frame_vsync	=	pre_frame_vsync;	            
wire			per2_frame_href	    =	pre_frame_href;	            
wire			per2_frame_clken	=	pre_frame_de;	            
wire	[7:0]	per2_img_red		=	{pre_rgb[23:16]};

//�ڶ�֡���ͼ��
wire        post2_frame_vsync ;
wire        post2_frame_href	; 
wire        post2_frame_clken ;
wire        post2_img_Bit		; 

//�ַ�����
wire   [20:0] 	char_boarder[7:0]	;
wire   [9:0] 	char_top 			;
wire   [9:0] 	char_down 			;

//�ַ��ָ�
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
//����֡ͼ���� �ַ�ʶ��

//����֡����ͼ��
wire			per3_frame_vsync	;            
wire			per3_frame_href 	;            
wire			per3_frame_clken	;            
wire        	per3_frame_data	;	

assign per3_frame_vsync = post2_frame_vsync;
assign per3_frame_href  = post2_frame_href;
assign per3_frame_clken = post2_frame_clken;
assign per3_frame_data =  post2_img_Bit;
 
wire [7:0]	    char_index [7:0];	//ƥ����ַ�����
wire			match_valid		 ;	//ƥ��ɹ���־

//�ַ�ʶ��
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
//���Ƴ��Ƹ�����ı߽�

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
	
 	//�ڲ�ɫͼ���ϻ�����          
	.per_frame_vsync		(per4_frame_vsync   ),	 
	.per_frame_href			(per4_frame_href    ),	 
    .per_frame_clken		(per4_frame_clken   ),	 
	.per_img_red			(per4_img_red	  ),		 
	.per_img_green			(per4_img_green	  ),	 
	.per_img_blue			(per4_img_blue	  ),		 

    //���߽�λ��
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
//��������ʶ������ĳ����ַ�

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

    //�����ַ�
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
// ������ 
assign	post_frame_vsync	=  post5_frame_vsync ;
assign	post_frame_href	    =  post5_frame_href  ;
assign	post_frame_de   	=  post5_frame_clken	;
assign	post_rgb    		=  {post5_img_red,post5_img_green,post5_img_blue};

endmodule