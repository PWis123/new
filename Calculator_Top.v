//计算器顶层模块
module Calculator_Top( 
Sysclk,Instr,St,En,
Instr_Addr, Finish, Result
);

input wire Sysclk;
input wire [7:0] Instr;
output reg [5:0] Instr_Addr = 0;
output reg Finish = 0;          //完成计算
output reg [15:0] Result = 0;

//总体控制
input wire En;        //使能信号，模块其为0的时候初始化
input wire St;        //计算使能

//FSM模块变量
reg FSM_EN = 0;
reg [15:0] FSM_Instr_reg = 0;
wire [7:0] FSM_Pointer;   //扫描指针
wire FSM_Fault;
wire FSM_Finish;
wire [15:0] FSM_Result;

//前处理模块变量
reg Pre_EN = 0;
wire [7:0] R_Pointer, W_Pointer;
wire [15:0] Pre_Outstr;
reg  [15:0] Pre_Instr_reg = 0;
wire Pre_Finish;

//Data_RAM_A模块变量
reg RAM_A_Wr = 0;
reg [7:0] RAM_A_Addr = 0;
reg [15:0] RAM_A_In = 0;
wire [15:0] RAM_A_Out;

//Data_RAM_B模块变量
reg RAM_B_Wr = 0;
reg [7:0] RAM_B_Addr = 0;
reg [15:0] RAM_B_In = 0;
wire [15:0] RAM_B_Out;

//本地变量
reg delay = 0;
reg Cal_Start = 0;
reg Finish_Reg = 0;

//-----------------------------------------------------------------------
//模块调用

//计算状态机
Calculator_FSM Calculator_FSM( 
Sysclk, FSM_EN, FSM_Pointer, FSM_Instr_reg,
FSM_Fault, FSM_Finish, FSM_Result
);

//前处理模块
PreProcess PreProcess( 
Sysclk, Pre_EN, R_Pointer, W_Pointer, 
Pre_Instr_reg, Pre_Outstr, Pre_Finish
);

//计算用的RAM
Data_Ram Data_Ram_B(
    Sysclk,
    RAM_B_Wr,
    RAM_B_Addr,
    RAM_B_In,
    RAM_B_Out   
);


//-----------------------------------------------------------------------
//控制盒
always@( * ) begin
    if ( !En ) begin   //初始化
    FSM_EN = 0;
    Pre_EN = 0;
    RAM_B_Wr = 0;
    RAM_B_Addr = 0;
    RAM_B_In = 0;    
    Cal_Start = 0;
    Finish_Reg = 0;
    end 
    else begin
        if (  Cal_Start == 0 && Pre_Finish == 0 && FSM_Finish == 0 ) begin
            if ( St ) begin
                Cal_Start = 1;
            end
        end
        else if (  Cal_Start == 1 && Pre_Finish == 0 && FSM_Finish == 0 ) begin
            Pre_EN = 1;
            Instr_Addr = R_Pointer[5:0];
            Pre_Instr_reg = {8'b0, Instr};
            RAM_B_Wr = 1;
            RAM_B_Addr = W_Pointer;
            RAM_B_In = Pre_Outstr;
        end
        else if ( Cal_Start == 1 && Pre_Finish == 1 && FSM_Finish == 0 ) begin
            FSM_EN = 1;
            RAM_B_Wr = 0;
            RAM_B_Addr = FSM_Pointer;
            FSM_Instr_reg = RAM_B_Out;
        end 
        else if ( Cal_Start == 1 && Pre_Finish == 1 && FSM_Finish == 1 ) begin      
            Finish_Reg = 1;
        end
    end
end

//结果输出
always@( * ) begin
    Result = FSM_Result;
end

always@( posedge Sysclk ) begin
    if ( Finish_Reg == 1 && delay == 0) begin
        Finish = 1;
        delay = delay + 1;    
    end
    else if ( Finish_Reg == 1 && delay == 1) begin
        Finish = 0;        
    end
    else begin
        Finish = 0;
        delay = 0;   
    end
end

endmodule