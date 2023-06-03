//表达式
module Experssion_Converter( 
Sysclk, En, Pointer, Instr,
Fault, Finish, Result
);
input wire Sysclk;
input wire En;                  //使能信号，模块其为0的时候初始化
input wire [7:0] Instr;         //传入的内容
output reg [7:0] Pointer = 0;   //扫描指针
output reg Fault = 0;
output reg Finish = 0;
output reg [15:0] Result = 0;

//数字栈变量
reg num_stack_clk   = 0;      // 可以用作堆栈控制
reg num_stack_rst_n = 1;
reg num_stack_pop = 0;
reg num_stack_push = 0;
reg [15:0] num_stack_datain = 0;
wire [15:0] num_stack_dataout;
wire [15:0] num_stack_Top;
wire num_stack_empty;
wire num_stack_full;

//符号栈变量
reg sym_stack_clk   = 0;      // 可以用作堆栈控制
reg sym_stack_rst_n = 1;
reg sym_stack_pop = 0;
reg sym_stack_push = 0;
reg [15:0] sym_stack_datain = 0;
wire [15:0] sym_stack_dataout;
wire [15:0] sym_stack_Top;
wire sym_stack_empty;
wire sym_stack_full;

//ALU模块变量
reg [15:0] SrcB, SrcA = 0;  //操作数与被操作数
reg [15:0] Last_Res = 0;
reg [1:0] ALU_Control = 0;  //0对应加 1对应减 2对应乘 3对应除
reg Src_Ready = 1;          //输入数据准备情况
wire [15:0] ALU_Result;
wire Result_Ready;

//译码模块变量
reg Decoder_Clr = 0;
reg Decoder_Clk = 0;
wire [15: 0] Bin_Out = 0;

//本模块变量
reg delay = 0;
reg Convert_Finish = 0;
reg [15:0] Postfix_Expression[255:0];

//-----------------------------------------------------------------------
//模块调用

//数字栈
    Stack Num_Stack(    
    num_stack_clk,      // 可以用作堆栈控制
    num_stack_rst_n,
    num_stack_pop,
    num_stack_push,
    num_stack_datain,
    num_stack_dataout,
    num_stack_Top,
    num_stack_empty,
    num_stack_full
    );
    
//符号栈    
    Stack Sym_Stack(    
    sym_stack_clk,      // 可以用作堆栈控制
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
    
//译码
    ASCII_2_Num_Decoder ASCII_2_Num_Decoder(
    Decoder_Clr, Decoder_Clk, Instr, Bin_Out
    );

//-----------------------------------------------------------------------
//控制盒
    always @( posedge Sysclk ) begin 
        if ( !En ) begin   //初始化         
     
        end
        else if ( En && !Convert_Finish ) begin
            case ( Instr )
                8'h00:begin //空操作符
                    if ( !sym_stack_empty ) begin
                        if ( delay == 0 ) begin
                            //出符号栈
                            sym_stack_push = 0;
                            sym_stack_pop = 1;
                            
                            //压数字栈
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
                        Convert_Finish = 1;//完成转换，开始计算  
                        delay = 0;
                        end
                    end                                    
                end
                8'h2A:begin //乘法
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
                8'h2F:begin //除法
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
                8'h2B:begin //加法 
                    if ( sym_stack_Top == 8'h2F || sym_stack_Top == 8'h2A ) begin
                        if ( delay == 0 ) begin
                            //出符号栈
                            sym_stack_push = 0;
                            sym_stack_pop = 1;
                            
                            //压数字栈
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
                    else begin //当栈顶符号为 + - （ 时
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
                8'h2D:begin //减法
                    if ( sym_stack_Top == 8'h2F || sym_stack_Top == 8'h2A ) begin
                        if ( delay == 0 ) begin
                            //出符号栈
                            sym_stack_push = 0;
                            sym_stack_pop = 1;
                            
                            //压数字栈
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
                    else begin //当栈顶符号为 + - （ 时
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
                8'h28:begin//左括号
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
                8'h29:begin//右括号
                    if ( sym_stack_Top != 8'h28 && !sym_stack_empty ) begin
                        if ( delay == 0 ) begin
                            //出符号栈
                            sym_stack_push = 0;
                            sym_stack_pop = 1;
                            
                            //压数字栈
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
                    else begin  //将左括号出栈
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
                default:begin//数字
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
        else begin //完成转换，开始输出表达式
        
        
        
        end    
    end
endmodule
