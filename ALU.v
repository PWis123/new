//ALU，仅支持加减乘除
//Src_Ready在计算中必须保证为1，如果Src_Ready出现下降沿，计算器会清除当前结果
module ALU( 
Sysclk, ALU_Control, SrcA, SrcB, 
Src_Ready, ALU_Result, Result_Ready,
fault
);
input wire Sysclk;                  //ALU时钟
input wire [1:0] ALU_Control;       //控制信号
input wire [15:0] SrcA,SrcB;        //操作数与被操作数
input wire Src_Ready;               //输入准备完成（上升沿）
output reg [15:0] ALU_Result = 0;       //ALU结果
output reg Result_Ready = 0;            //答案计算完成
output reg fault = 0;                   //未知错误

reg [2:0] clk_cnt = 0;
wire [15:0] Mul_Result;
wire [31:0] Div_Result;
reg Src_Ready_in = 0;

//-----------------------------------------------------------------------
    //除法IP核，有5个clk的延时，ready信号的高电平表示完成计算
    Divider Divider (
      .aclk(Sysclk),                    // 时钟
      .s_axis_divisor_tvalid(1),        // 操作数使能
      .s_axis_divisor_tdata(SrcB),      // 除数
      .s_axis_dividend_tvalid(1),       // 操作数使能
      .s_axis_dividend_tdata(SrcA),     // 被除数
      .m_axis_dout_tvalid(),            // 除法器初始化完成
      .m_axis_dout_tdata(Div_Result)    // 32位结果 低16位为余数，高16位为商
    );
    
    //乘法IP核，有5个clk的延时，ready信号的高电平表示完成计算,注意需要5个周期进行初始化
    Multiplier Multiplier (
      .CLK(Sysclk),                     // 时钟
      .A(SrcA),                         // 操作数
      .B(SrcB),                         // 操作数
      .P(Mul_Result)                    // 结果
    );

//-----------------------------------------------------------------------
//注意当计算完成后的第一个时钟周期不能输入数据        
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
//Src_Ready在计算中必须保证为1，如果Src_Ready出现下降沿，计算器会清除当前结果
    always@( Src_Ready ) begin 
        if ( Src_Ready == 1 ) begin
            Src_Ready_in = 1;        
        end
        else begin
            Src_Ready_in = 0; 
        end
    end
    
endmodule