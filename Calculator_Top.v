//����������ģ��
module Calculator_Top( 
Sysclk,Instr,St,En,
Instr_Addr, Finish, Result
);

input wire Sysclk;
input wire [7:0] Instr;
output reg [5:0] Instr_Addr = 0;
output reg Finish = 0;          //��ɼ���
output reg [15:0] Result = 0;

//�������
input wire En;        //ʹ���źţ�ģ����Ϊ0��ʱ���ʼ��
input wire St;        //����ʹ��

//FSMģ�����
reg FSM_EN = 0;
reg [15:0] FSM_Instr_reg = 0;
wire [7:0] FSM_Pointer;   //ɨ��ָ��
wire FSM_Fault;
wire FSM_Finish;
wire [15:0] FSM_Result;

//ǰ����ģ�����
reg Pre_EN = 0;
wire [7:0] R_Pointer, W_Pointer;
wire [15:0] Pre_Outstr;
reg  [15:0] Pre_Instr_reg = 0;
wire Pre_Finish;

//Data_RAM_Aģ�����
reg RAM_A_Wr = 0;
reg [7:0] RAM_A_Addr = 0;
reg [15:0] RAM_A_In = 0;
wire [15:0] RAM_A_Out;

//Data_RAM_Bģ�����
reg RAM_B_Wr = 0;
reg [7:0] RAM_B_Addr = 0;
reg [15:0] RAM_B_In = 0;
wire [15:0] RAM_B_Out;

//���ر���
reg delay = 0;
reg Cal_Start = 0;
reg Finish_Reg = 0;

//-----------------------------------------------------------------------
//ģ�����

//����״̬��
Calculator_FSM Calculator_FSM( 
Sysclk, FSM_EN, FSM_Pointer, FSM_Instr_reg,
FSM_Fault, FSM_Finish, FSM_Result
);

//ǰ����ģ��
PreProcess PreProcess( 
Sysclk, Pre_EN, R_Pointer, W_Pointer, 
Pre_Instr_reg, Pre_Outstr, Pre_Finish
);

//�����õ�RAM
Data_Ram Data_Ram_B(
    Sysclk,
    RAM_B_Wr,
    RAM_B_Addr,
    RAM_B_In,
    RAM_B_Out   
);


//-----------------------------------------------------------------------
//���ƺ�
always@( * ) begin
    if ( !En ) begin   //��ʼ��
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

//������
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