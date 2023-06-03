//���ʽ
module Experssion_Converter( 
Sysclk, En, Pointer, Instr,
Fault, Finish, Result
);
input wire Sysclk;
input wire En;                  //ʹ���źţ�ģ����Ϊ0��ʱ���ʼ��
input wire [7:0] Instr;         //���������
output reg [7:0] Pointer = 0;   //ɨ��ָ��
output reg Fault = 0;
output reg Finish = 0;
output reg [15:0] Result = 0;

//����ջ����
reg num_stack_clk   = 0;      // ����������ջ����
reg num_stack_rst_n = 1;
reg num_stack_pop = 0;
reg num_stack_push = 0;
reg [15:0] num_stack_datain = 0;
wire [15:0] num_stack_dataout;
wire [15:0] num_stack_Top;
wire num_stack_empty;
wire num_stack_full;

//����ջ����
reg sym_stack_clk   = 0;      // ����������ջ����
reg sym_stack_rst_n = 1;
reg sym_stack_pop = 0;
reg sym_stack_push = 0;
reg [15:0] sym_stack_datain = 0;
wire [15:0] sym_stack_dataout;
wire [15:0] sym_stack_Top;
wire sym_stack_empty;
wire sym_stack_full;

//ALUģ�����
reg [15:0] SrcB, SrcA = 0;  //�������뱻������
reg [15:0] Last_Res = 0;
reg [1:0] ALU_Control = 0;  //0��Ӧ�� 1��Ӧ�� 2��Ӧ�� 3��Ӧ��
reg Src_Ready = 1;          //��������׼�����
wire [15:0] ALU_Result;
wire Result_Ready;

//����ģ�����
reg Decoder_Clr = 0;
reg Decoder_Clk = 0;
wire [15: 0] Bin_Out = 0;

//��ģ�����
reg delay = 0;
reg Convert_Finish = 0;
reg [15:0] Postfix_Expression[255:0];

//-----------------------------------------------------------------------
//ģ�����

//����ջ
    Stack Num_Stack(    
    num_stack_clk,      // ����������ջ����
    num_stack_rst_n,
    num_stack_pop,
    num_stack_push,
    num_stack_datain,
    num_stack_dataout,
    num_stack_Top,
    num_stack_empty,
    num_stack_full
    );
    
//����ջ    
    Stack Sym_Stack(    
    sym_stack_clk,      // ����������ջ����
    sym_stack_rst_n,
    sym_stack_pop,
    sym_stack_push,
    sym_stack_datain,
    sym_stack_dataout,
    sym_stack_Top,
    sym_stack_empty,
    sym_stack_full
    );

//ALU
    ALU ALU(            
    .Sysclk(Sysclk), 
    .ALU_Control(ALU_Control), 
    .SrcA(SrcA), 
    .SrcB(SrcB), 
    .Src_Ready(Src_Ready), 
    .ALU_Result(ALU_Result), 
    .Result_Ready(Result_Ready)
    );
    
//����
    ASCII_2_Num_Decoder ASCII_2_Num_Decoder(
    Decoder_Clr, Decoder_Clk, Instr, Bin_Out
    );

//-----------------------------------------------------------------------
//���ƺ�
    always @( posedge Sysclk ) begin 
        if ( !En ) begin   //��ʼ��         
     
        end
        else if ( En && !Convert_Finish ) begin
            case ( Instr )
                8'h00:begin //�ղ�����
                    if ( !sym_stack_empty ) begin
                        if ( delay == 0 ) begin
                            //������ջ
                            sym_stack_push = 0;
                            sym_stack_pop = 1;
                            
                            //ѹ����ջ
                            num_stack_push = 1;
                            num_stack_pop = 0;
                            num_stack_datain = sym_stack_Top; 
                            delay = 1;
                        end
                        else begin
                            num_stack_clk = ~num_stack_clk;
                            sym_stack_clk = ~sym_stack_clk;
                            delay = 0;
                        end                                        
                    end
                    else begin
                        if ( delay == 0 ) begin
                        num_stack_push = 1;
                        num_stack_pop = 0;
                        num_stack_datain = 8'h00;                         
                        delay = 1;
                        end
                        else begin
                        num_stack_clk = ~num_stack_clk;                        
                        Convert_Finish = 1;//���ת������ʼ����  
                        delay = 0;
                        end
                    end                                    
                end
                8'h2A:begin //�˷�
                    if ( delay == 0 ) begin
                        sym_stack_push = 1;
                        sym_stack_pop = 0;
                        sym_stack_datain = 8'h2A;
                        delay = 1;
                    end
                    else begin
                        sym_stack_clk = ~sym_stack_clk;
                        delay = 0;
                        Pointer = Pointer + 1;
                    end         
                end
                8'h2F:begin //����
                    if ( delay == 0 ) begin
                        sym_stack_push = 1;
                        sym_stack_pop = 0;
                        sym_stack_datain = 8'h2F;
                        delay = 1;
                    end
                    else begin
                        sym_stack_clk = ~sym_stack_clk;
                        delay = 0;
                        Pointer = Pointer + 1;                        
                    end                                
                end
                8'h2B:begin //�ӷ� 
                    if ( sym_stack_Top == 8'h2F || sym_stack_Top == 8'h2A ) begin
                        if ( delay == 0 ) begin
                            //������ջ
                            sym_stack_push = 0;
                            sym_stack_pop = 1;
                            
                            //ѹ����ջ
                            num_stack_push = 1;
                            num_stack_pop = 0;
                            num_stack_datain = sym_stack_Top; 
                            delay = 1;
                        end
                        else begin
                            num_stack_clk = ~num_stack_clk;
                            sym_stack_clk = ~sym_stack_clk;
                            delay = 0;
                        end                                                                                                  
                    end
                    else begin //��ջ������Ϊ + - �� ʱ
                        if ( delay == 0 ) begin
                            sym_stack_push = 1;
                            sym_stack_pop = 0;
                            sym_stack_datain = 8'h2B;
                            delay = 1;
                        end
                        else begin
                            sym_stack_clk = ~sym_stack_clk;
                            delay = 0;
                            Pointer = Pointer + 1;                            
                        end                                        
                    end                
                end
                8'h2D:begin //����
                    if ( sym_stack_Top == 8'h2F || sym_stack_Top == 8'h2A ) begin
                        if ( delay == 0 ) begin
                            //������ջ
                            sym_stack_push = 0;
                            sym_stack_pop = 1;
                            
                            //ѹ����ջ
                            num_stack_push = 1;
                            num_stack_pop = 0;
                            num_stack_datain = sym_stack_Top; 
                            delay = 1;
                        end
                        else begin
                            num_stack_clk = ~num_stack_clk;
                            sym_stack_clk = ~sym_stack_clk;
                            delay = 0;
                        end                                                                                              
                    end
                    else begin //��ջ������Ϊ + - �� ʱ
                        if ( delay == 0 ) begin
                            sym_stack_push = 1;
                            sym_stack_pop = 0;
                            sym_stack_datain = 8'h2D;
                            delay = 1;
                        end
                        else begin
                            sym_stack_clk = ~sym_stack_clk;
                            delay = 0;
                            Pointer = Pointer + 1;                            
                        end                                        
                    end                                                      
                end
                8'h28:begin//������
                    if ( delay == 0 ) begin
                        num_stack_push = 1;
                        sym_stack_pop = 0;
                        sym_stack_datain = 8'h28;
                        delay = 1;
                    end
                    else begin
                        sym_stack_clk = ~sym_stack_clk;
                        delay = 0;
                        Pointer = Pointer + 1;
                    end
                end
                8'h29:begin//������
                    if ( sym_stack_Top != 8'h28 && !sym_stack_empty ) begin
                        if ( delay == 0 ) begin
                            //������ջ
                            sym_stack_push = 0;
                            sym_stack_pop = 1;
                            
                            //ѹ����ջ
                            num_stack_push = 1;
                            num_stack_pop = 0;
                            num_stack_datain = sym_stack_Top; 
                            delay = 1;
                        end
                        else begin
                            num_stack_clk = ~num_stack_clk;
                            sym_stack_clk = ~sym_stack_clk;
                            delay = 0;
                        end                              
                    end
                    else begin  //�������ų�ջ
                        if ( delay == 0 ) begin
                            sym_stack_push = 0;
                            sym_stack_pop = 1;
                            delay = 1;
                        end
                        else begin
                            sym_stack_clk = ~sym_stack_clk;
                            delay = 0;
                            Pointer = Pointer + 1;                            
                        end  
                    end
                end                                      
                default:begin//����
                    if ( delay == 0 ) begin
                        num_stack_push = 1;
                        num_stack_pop = 0;
                        num_stack_datain = Instr;
                        delay = 1;
                    end
                    else begin
                        num_stack_clk = ~num_stack_clk;
                        delay = 0;
                        Pointer = Pointer + 1;                        
                    end                                            
                end    
            endcase
        end
        else begin //���ת������ʼ������ʽ
        
        
        
        end    
    end
endmodule
