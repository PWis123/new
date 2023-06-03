//ALU����֧�ּӼ��˳�
//Src_Ready�ڼ����б��뱣֤Ϊ1�����Src_Ready�����½��أ��������������ǰ���
module ALU( 
Sysclk, ALU_Control, SrcA, SrcB, 
Src_Ready, ALU_Result, Result_Ready,
fault
);
input wire Sysclk;                  //ALUʱ��
input wire [1:0] ALU_Control;       //�����ź�
input wire [15:0] SrcA,SrcB;        //�������뱻������
input wire Src_Ready;               //����׼����ɣ������أ�
output reg [15:0] ALU_Result = 0;       //ALU���
output reg Result_Ready = 0;            //�𰸼������
output reg fault = 0;                   //δ֪����

reg [2:0] clk_cnt = 0;
wire [15:0] Mul_Result;
wire [31:0] Div_Result;
reg Src_Ready_in = 0;

//-----------------------------------------------------------------------
    //����IP�ˣ���5��clk����ʱ��ready�źŵĸߵ�ƽ��ʾ��ɼ���
    Divider Divider (
      .aclk(Sysclk),                    // ʱ��
      .s_axis_divisor_tvalid(1),        // ������ʹ��
      .s_axis_divisor_tdata(SrcB),      // ����
      .s_axis_dividend_tvalid(1),       // ������ʹ��
      .s_axis_dividend_tdata(SrcA),     // ������
      .m_axis_dout_tvalid(),            // ��������ʼ�����
      .m_axis_dout_tdata(Div_Result)    // 32λ��� ��16λΪ��������16λΪ��
    );
    
    //�˷�IP�ˣ���5��clk����ʱ��ready�źŵĸߵ�ƽ��ʾ��ɼ���,ע����Ҫ5�����ڽ��г�ʼ��
    Multiplier Multiplier (
      .CLK(Sysclk),                     // ʱ��
      .A(SrcA),                         // ������
      .B(SrcB),                         // ������
      .P(Mul_Result)                    // ���
    );

//-----------------------------------------------------------------------
//ע�⵱������ɺ�ĵ�һ��ʱ�����ڲ�����������        
    always@( posedge Sysclk) begin
        if ( Src_Ready_in && !Result_Ready )
            case( ALU_Control ) 
                2'b00: begin             // add            
                    ALU_Result = SrcA + SrcB;
                    Result_Ready = 1;           
                end
                2'b01: begin             // sub                                     
                    ALU_Result = SrcA - SrcB;
                    Result_Ready = 1;                                        
                end
                2'b10: begin             // mul             
                    if ( clk_cnt < 5 )begin
                        ALU_Result = 0;
                        clk_cnt = clk_cnt + 1;
                    end
                    else begin
                        ALU_Result = Mul_Result; 
                        Result_Ready = 1;
                        clk_cnt = 0;                    
                    end                  
                end
                2'b11: begin             // div                 
                    if ( clk_cnt < 5 )begin
                        ALU_Result = 0;
                        clk_cnt = clk_cnt + 1;
                    end
                    else begin
                        ALU_Result = Div_Result[31:16]; 
                        Result_Ready = 1;
                        clk_cnt = 0;                    
                    end                    
                end                        
                default:begin             // fault
                    fault = 1;
                    end 
            endcase            
        else if ( Src_Ready_in && Result_Ready )begin

        end
        else begin
            clk_cnt = 0;
            Result_Ready = 0;    
        end
    end
    
//-----------------------------------------------------------------------
//Src_Ready�ڼ����б��뱣֤Ϊ1�����Src_Ready�����½��أ��������������ǰ���
    always@( Src_Ready ) begin 
        if ( Src_Ready == 1 ) begin
            Src_Ready_in = 1;        
        end
        else begin
            Src_Ready_in = 0; 
        end
    end
    
endmodule