module plate_feature_recognize
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
	// output				post_frame_vsync,	//Processed Image data vsync valid signal
	// output				post_frame_href,	//Processed Image data href vaild  signal
	// output				post_frame_clken,	//Processed Image data output/capture enable clock
	// output				post_img_Bit, 		//Processed Image Bit flag outout(1: Value, 0:inValid)

	input       [20:0] 	char_boarder[7:0],			//�������ַ���λ��
    input     	[9:0]  	char_top	,  	
    input     	[9:0]  	char_down ,

//	output reg  [0:4] 	char_feature  [7:0] [7:0], //���ַ�������ֵ���Զ�ά�������ʽ����
	output reg  [0:4] 	char_feature  [7:0] [7:0], //���ַ�������ֵ���Զ�ά�������ʽ����
	output               char_feature_valid
	);

	
//------------------------------------------
//lag 1 clocks signal sync  

reg			per_frame_vsync_r;
reg			per_frame_href_r;	
reg			per_frame_clken_r;
reg  		per_img_Bit_r;

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

assign char_feature_valid = vsync_neg_flag;

//------------------------------------------
//����������ؽ���"��/��"����������õ����ݺ�����
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
//�Ĵ��ݺ�����
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
wire [7:0] char_flag			;		//���ַ�����Ч��־
wire [9:0] char_left 	[7:0] 	;		//���ַ�����/�ұ߽�
wire [9:0] char_right 	[7:0] 	;

wire [9:0] char_width 	[7:0] 	;		//���ַ��Ŀ�/��

wire [9:0] char_height = char_down - char_top ;	 		 


reg [9:0] x_div_num	[7:0]	;		//��ǰ���ض��ڸ��ַ�����ķ������
reg [9:0] y_div_num	[7:0]	;		//��ǰ���ض��ڸ��ַ�����ķ������

reg [7:0] div_width  [7:0];				//�����ַ����ֳ�8*5����
reg [7:0] div_height [7:0];

reg [7:0] div_pixel_sum[7:0];			//ÿ���ַ������������ܺ�

wire[9:0] x_div_num_ok	[7:0]	;		//��ǰ���ض��ڸ��ַ�����ķ�����ţ��ų�����4�Ĳ��֣�
wire[9:0] y_div_num_ok	[7:0]	;		//��ǰ���ض��ڸ��ַ�����ķ�����ţ��ų�����7�Ĳ��֣�

generate
genvar i;
	for(i=0; i<8; i = i+1) begin : CHAR_DATA
		assign char_flag[i]		= char_boarder[i][20];
		assign char_left[i]		= char_boarder[i][19:10];
		assign char_right[i] 	= char_boarder[i][ 9: 0];
				
		assign char_width[i] 	= char_boarder[i][ 9: 0] - char_boarder[i][19:10] ;
		//assign char_height  	= char_down - char_top ;
		
		assign x_div_num_ok[i]  = (x_div_num[i] > 4) ? 4 : x_div_num[i];
		assign y_div_num_ok[i]  = (y_div_num[i] > 7) ? 7 : y_div_num[i];
	end
endgenerate

//------------------------------------------

//����ָ��ַ�����8x5����� ���/�߶�/�Լ���ǰ���ص�ķ�����
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
			
		if(x_cnt > char_left[k]) begin					//��ǰһ��ʱ�����ڼ��㵱ǰ���ص������ַ����ĸ�������
			x_div_num[k] <= (x_cnt-char_left[k]) / div_width[k] ;
		end
		
		if(y_cnt > char_top) begin
			y_div_num[k] <= (y_cnt-char_top) / div_height[k];
		end		
		
		div_pixel_sum[k] <= (div_width[k] * div_height[k])/2;
        
		//div_pixel_sum[k] <= (3 * div_width[k] * div_height[k]) / 5;
			
            
	end
end




//------------------------------------------
//��ÿ���ַ���40������������Ϊ1�����ؽ��м���
reg [7:0] pixel_cnt [7:0] [7:0] [4:0];	// 8���ַ� | 8�� | 5��  

integer m;
integer n;
integer p;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin						//��ʼ��
		for(m=0; m<8; m = m+1) begin			//����8���ַ�
			for(n=0; n<8; n = n+1) begin		//����8��
				for(p=0; p<5; p = p+1) begin	//����5��
					pixel_cnt[m][n][p] <= 8'd0;
				end			
			end			
		end
	end
	else if(y_cnt_r == 1)begin   						//��һ֡��ʼ���г�ʼ��
		for(m=0; m<8; m = m+1) begin			//����8���ַ�
			for(n=0; n<8; n = n+1) begin		//����8��
				for(p=0; p<5; p = p+1) begin	//����5��
					pixel_cnt[m][n][p] <= 8'd0;
				end			
			end			
		end
	end 	
    else if(y_cnt_r <= char_down) begin
        for(m=0; m<8; m = m+1) begin	
            //�жϵ�ǰ���������ĸ��ַ���������
            if((x_cnt_r >=  char_left[m]) && (x_cnt_r < char_right[m]) && (y_cnt_r > char_top) && (y_cnt_r < char_down) )  begin
				if(per_img_Bit_r && per_frame_clken_r) //��ǰ����Ϊ1
					pixel_cnt[m][y_div_num_ok[m]][x_div_num_ok[m]] <= pixel_cnt[m][y_div_num_ok[m]][x_div_num_ok[m]] + 1'b1;
			end
        end
    end	 
end

//------------------------------------------
//������ַ�������ֵ���Զ�ά�������ʽ����

integer r;
integer s;
integer t;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin							//��ʼ��
		for(r=0; r<8; r = r+1) begin			//����8���ַ�
			for(s=0; s<8; s = s+1) begin
				char_feature[r][s]  <= 5'd0;
			end
		end
	end
	else if(y_cnt_r == char_down + 1)begin			//�ڸ�������Ϊ1��������ͳ����ɺ�ͳ������ֵ
		for(r=0; r<8; r = r+1) begin			//����8���ַ�
			for(s=0; s<8; s = s+1) begin		//����8��
				for(t=0; t<5; t = t+1) begin	//����5��
				
					if(pixel_cnt[r][s][t] > div_pixel_sum[r])			//������Ϊ1������������1/2���ж�����ֵΪ1
						char_feature[r][s][t] <= 1'b1;			 
					else
						char_feature[r][s][t] <= 1'b0;
				end			
			end			
		end
	end 	
end

endmodule