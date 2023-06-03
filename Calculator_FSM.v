//�����״̬��,��תΪ��׺���ʽ���ٽ��м���
module Calculator_FSM( 
Sysclk, En, Pointer, Instr,
Fault, Finish, Result
);
input wire Sysclk;
input wire En;                  //ʹ���źţ�ģ����Ϊ0��ʱ���ʼ��
input wire [15:0] Instr;         //���������
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
reg [15:0] SrcB = 0, SrcA = 0;  //�������뱻������
reg [1:0] ALU_Control = 0;      //0��Ӧ�� 1��Ӧ�� 2��Ӧ�� 3��Ӧ��
reg Src_Ready = 0;              //��������׼�����
wire [15:0] ALU_Result;
wire Result_Ready;

//��ģ�����
reg SW = 0; //stack���÷�ת
reg [3:0] delay = 0;
reg Convert_Finish = 0;

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
    

//-----------------------------------------------------------------------
//���ƺ�
    always @( posedge Sysclk ) begin 
        if ( !En ) begin   //��ʼ��
            //ϵͳ����
            Fault = 0;  
            Pointer = 0;  
            Finish = 0;
            Result = 0;        
            //ALU����          
            SrcA = 0;
            SrcB = 0;
            ALU_Control = 0;  
            Src_Ready = 0;          
            //����ջ����
            num_stack_clk   = 0;      
            num_stack_rst_n = 1;
            num_stack_pop = 0;
            num_stack_push = 0;
            num_stack_datain = 0;
            //����ջ����
            sym_stack_clk   = 0;      
            sym_stack_rst_n = 1;
            sym_stack_pop = 0;
            sym_stack_push = 0;
            sym_stack_datain = 0;             
        end
        else if ( En && !Convert_Finish ) begin
            case ( Instr )
                16'h8001:begin //�ղ�����
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
                        num_stack_datain = 16'h8001;                         
                        delay = 1;
                        end
                        else begin
                        num_stack_clk = ~num_stack_clk;                        
                        Convert_Finish = 1;//���ת������ʼ����  
                        delay = 0;
                        end
                    end                                    
                end
                16'h8002:begin //�˷�
                    if ( sym_stack_Top == 16'h8003 ) begin
                        if ( delay == 0 ) begin
                            //������ջ
                            sym_stack_push = 0;
                            sym_stack_pop = 1;
                            
                            //ѹ����ջ
                            num_stack_push = 1;
                            num_stack_pop = 0;
                            num_stack_datain = 16'h8003; 
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
                            sym_stack_datain = 16'h8002;
                            delay = 1;
                        end
                        else begin
                            sym_stack_clk = ~sym_stack_clk;
                            delay = 0;
                            Pointer = Pointer + 1;                            
                        end                                        
                    end                                                      
                end
                16'h8003:begin //����
                    if ( delay == 0 ) begin
                        sym_stack_push = 1;
                        sym_stack_pop = 0;
                        sym_stack_datain = 16'h8003;
                        delay = 1;
                    end
                    else begin
                        sym_stack_clk = ~sym_stack_clk;
                        delay = 0;
                        Pointer = Pointer + 1;                        
                    end                                
                end
                16'h7FFF:begin //�ӷ� 
                    if ( sym_stack_Top == 16'h8003 || sym_stack_Top == 16'h8002 || sym_stack_Top == 16'h7FFE ) begin
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
                    else begin //��ջ������Ϊ +�� ʱ
                        if ( delay == 0 ) begin
                            sym_stack_push = 1;
                            sym_stack_pop = 0;
                            sym_stack_datain = 16'h7FFF;
                            delay = 1;
                        end
                        else begin
                            sym_stack_clk = ~sym_stack_clk;
                            delay = 0;
                            Pointer = Pointer + 1;                            
                        end                                        
                    end                
                end
                16'h7FFE:begin //����
                    if ( sym_stack_Top == 16'h8003 || sym_stack_Top == 16'h8002 ) begin
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
                            sym_stack_datain = 16'h7FFE;
                            delay = 1;
                        end
                        else begin
                            sym_stack_clk = ~sym_stack_clk;
                            delay = 0;
                            Pointer = Pointer + 1;                            
                        end                                        
                    end                                                      
                end
                16'h7FFC:begin//������
                    if ( delay == 0 ) begin
                        num_stack_push = 1;
                        sym_stack_pop = 0;
                        sym_stack_datain = 16'h7FFC;
                        delay = 1;
                    end
                    else begin
                        sym_stack_clk = ~sym_stack_clk;
                        delay = 0;
                        Pointer = Pointer + 1;
                    end
                end
                16'h7FFD:begin//������
                    if ( sym_stack_Top != 16'h7FFC && !sym_stack_empty ) begin
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
        else begin //���ת����תΪʹ��symstack���б��ʽ����
            if ( !num_stack_empty && !SW ) begin
                if ( delay == 0 ) begin
                    //������ջ
                    num_stack_push = 0;
                    num_stack_pop = 1;
                    
                    //ѹ����ջ
                    sym_stack_push = 1;
                    sym_stack_pop = 0;
                    sym_stack_datain = num_stack_Top; 
                    delay = 1;
                end
                else begin
                    num_stack_clk = ~num_stack_clk;
                    sym_stack_clk = ~sym_stack_clk;
                    delay = 0;
                end                                        
            end
            else if ( num_stack_empty && !SW )begin
                SW = 1;
            end
            else begin //���ɨ��˳��ת����ʹ��numstack��Ϊ�����ջ
                case( sym_stack_Top )                
                    16'h8001:begin
                        Finish = 1;
                        Result = num_stack_Top;
                    end                    
                    16'h8002:begin //�˷� 
                        if ( delay == 0 ) begin
                            //������ջ
                            num_stack_push = 0;
                            num_stack_pop = 1;                            
                            SrcB = num_stack_Top;
                            ALU_Control = 2;
                            delay = 1;                            
                        end
                        else if ( delay == 1 ) begin
                            num_stack_clk = ~num_stack_clk;
                            delay = 2;                          
                        end
                        else if ( delay == 2 ) begin
                            SrcA = num_stack_Top;
                            delay = 3;                                                  
                        end
                        else if ( delay == 3 ) begin
                            Src_Ready = 1;                            
                            num_stack_clk = ~num_stack_clk;
                            delay = 4;                          
                        end
                        else if ( delay == 4 ) begin
                            if ( Result_Ready ) begin
                                //ѹ����ջ
                                num_stack_push = 1;
                                num_stack_pop = 0;
                                num_stack_datain = ALU_Result;                          
                                 
                                //������ջ
                                sym_stack_push = 0;
                                sym_stack_pop = 1;                               
                                
                                delay = 5;
                            end                        
                        end
                        else if ( delay == 5 ) begin
                            num_stack_clk = ~num_stack_clk;
                            sym_stack_clk = ~sym_stack_clk;
                            Src_Ready = 0; 
                            delay = 0;                        
                        end                                               
                    end
                    
                    16'h8003:begin //����
                        if ( delay == 0 ) begin
                            //������ջ
                            num_stack_push = 0;
                            num_stack_pop = 1;                            
                            SrcB = num_stack_Top;
                            ALU_Control = 3;
                            delay = 1;                            
                        end
                        else if ( delay == 1 ) begin
                            num_stack_clk = ~num_stack_clk;
                            delay = 2;                          
                        end
                        else if ( delay == 2 ) begin
                            SrcA = num_stack_Top;
                            delay = 3;                                                  
                        end
                        else if ( delay == 3 ) begin
                            Src_Ready = 1;                            
                            num_stack_clk = ~num_stack_clk;
                            delay = 4;                          
                        end
                        else if ( delay == 4 ) begin
                            if ( Result_Ready ) begin
                                //ѹ����ջ
                                num_stack_push = 1;
                                num_stack_pop = 0;
                                num_stack_datain = ALU_Result;                          
                                 
                                //������ջ
                                sym_stack_push = 0;
                                sym_stack_pop = 1;                               
                                
                                delay = 5;
                            end                        
                        end
                        else if ( delay == 5 ) begin
                            num_stack_clk = ~num_stack_clk;
                            sym_stack_clk = ~sym_stack_clk;
                            Src_Ready = 0; 
                            delay = 0;                        
                        end                                               
                    end           
                                                  
                    16'h7FFF:begin //�ӷ� 
                        if ( delay == 0 ) begin
                            //������ջ
                            num_stack_push = 0;
                            num_stack_pop = 1;                            
                            SrcB = num_stack_Top;
                            ALU_Control = 0;
                            delay = 1;                            
                        end
                        else if ( delay == 1 ) begin
                            num_stack_clk = ~num_stack_clk;
                            delay = 2;                          
                        end
                        else if ( delay == 2 ) begin
                            SrcA = num_stack_Top;
                            delay = 3;                                                  
                        end
                        else if ( delay == 3 ) begin
                            Src_Ready = 1;                            
                            num_stack_clk = ~num_stack_clk;
                            delay = 4;                          
                        end
                        else if ( delay == 4 ) begin
                            if ( Result_Ready ) begin
                                //ѹ����ջ
                                num_stack_push = 1;
                                num_stack_pop = 0;
                                num_stack_datain = ALU_Result;                          
                                 
                                //������ջ
                                sym_stack_push = 0;
                                sym_stack_pop = 1;                               
                                
                                delay = 5;
                            end                        
                        end
                        else if ( delay == 5 ) begin
                            num_stack_clk = ~num_stack_clk;
                            sym_stack_clk = ~sym_stack_clk;
                            Src_Ready = 0; 
                            delay = 0;                        
                        end                                               
                    end                    
                    
                    16'h7FFE:begin //����
                        if ( delay == 0 ) begin
                            //������ջ
                            num_stack_push = 0;
                            num_stack_pop = 1;                            
                            SrcB = num_stack_Top;
                            ALU_Control = 1;
                            delay = 1;                            
                        end
                        else if ( delay == 1 ) begin
                            num_stack_clk = ~num_stack_clk;
                            delay = 2;                          
                        end
                        else if ( delay == 2 ) begin
                            SrcA = num_stack_Top;
                            delay = 3;                                                  
                        end
                        else if ( delay == 3 ) begin
                            Src_Ready = 1;                            
                            num_stack_clk = ~num_stack_clk;
                            delay = 4;                          
                        end
                        else if ( delay == 4 ) begin
                            if ( Result_Ready ) begin
                                //ѹ����ջ
                                num_stack_push = 1;
                                num_stack_pop = 0;
                                num_stack_datain = ALU_Result;                          
                                 
                                //������ջ
                                sym_stack_push = 0;
                                sym_stack_pop = 1;                               
                                
                                delay = 5;
                            end                        
                        end
                        else if ( delay == 5 ) begin
                            num_stack_clk = ~num_stack_clk;
                            sym_stack_clk = ~sym_stack_clk;
                            Src_Ready = 0; 
                            delay = 0;                        
                        end                                               
                    end 
                                        
                    default: begin //����
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
                endcase
            end                 
        end    
    end
endmodule
