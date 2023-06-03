//ǰ����ģ�飬��ASCII��ʽתΪԤ�趨����ʽ��ʽ
//
module PreProcess( 
Sysclk, En, R_Pointer, W_Pointer, 
Instr, Outstr, Finish
);
input wire Sysclk;
input wire En;                      //ʹ���źţ�ģ����Ϊ0��ʱ���ʼ��
input wire [15:0] Instr;            //���������
output reg [7:0] R_Pointer = 0;     //��ȡָ��
output reg [7:0] W_Pointer = 0;     //д��ָ��
output reg [15:0] Outstr = 0;       //����������
output reg Finish = 0;

//����ģ�����
reg Decoder_Clr = 1;
reg Decoder_Clk = 0;
reg Nege = 0;
wire [15:0] Bin_Out;

//���ر���
reg [2:0] delay = 0;
reg [1:0] Sym_Rec = 0; //0���������� 1������  2��������  3:������

//-----------------------------------------------------------------------
//ģ�����
//����
    ASCII_2_Num_Decoder ASCII_2_Num_Decoder(
    Decoder_Clr, Decoder_Clk, Nege, Instr[7:0], Bin_Out
    );

//-----------------------------------------------------------------------
//���ƺ�
always@( posedge Sysclk ) begin
    if ( !En ) begin   //��ʼ��
        delay = 0;
        Finish = 0;
        Outstr = 0;
        W_Pointer = 0;
        R_Pointer = 0;
        Decoder_Clr = 1;
        Decoder_Clk = !Decoder_Clk;
        Sym_Rec = 0;
        Nege = 0;
    end 
    else begin
        case ( Instr ) 
            16'h000D: begin // ��
                if ( delay == 0 ) begin
                    Outstr = 16'h8001;
                    W_Pointer = W_Pointer + 1;
                    delay = 1;                
                end
                else begin
                    delay = 0;
                    Finish = 1;
                end                           
            end        
            16'h002A: begin // *
                if ( Sym_Rec == 3 ) begin
                    if ( delay == 0 ) begin
                        Outstr = 16'h8002;
                        delay = 1;                
                    end
                    else begin
                        W_Pointer = W_Pointer + 1;
                        R_Pointer = R_Pointer + 1;
                        delay = 0;
                        Sym_Rec = 0;
                    end                
                end
                else begin
                    if ( delay == 0 ) begin
                        Outstr = Bin_Out;
                        delay = 1;
                        Decoder_Clr = 1;                
                    end
                    else if ( delay == 1 ) begin
                        W_Pointer = W_Pointer + 1;
                        Decoder_Clk = !Decoder_Clk;
                        Nege = 0;
                        delay = 2;
                    end                
                    else if ( delay == 2 ) begin
                        Outstr = 16'h8002;
                        delay = 3;                
                    end
                    else begin
                        W_Pointer = W_Pointer + 1;
                        R_Pointer = R_Pointer + 1;
                        delay = 0;
                        Sym_Rec = 0;
                    end 
                end
            end
            16'h002F: begin // /
                if ( Sym_Rec == 3 ) begin
                    if ( delay == 0 ) begin
                        Outstr = 16'h8003;
                        delay = 1;                
                    end
                    else begin
                        W_Pointer = W_Pointer + 1;
                        R_Pointer = R_Pointer + 1;
                        delay = 0;
                        Sym_Rec = 0;
                    end                
                end
                else begin                        
                    if ( delay == 0 ) begin
                        Outstr = Bin_Out;
                        delay = 1;    
                        Decoder_Clr = 1;             
                    end
                    else if ( delay == 1 ) begin
                        W_Pointer = W_Pointer + 1;
                        Decoder_Clk = !Decoder_Clk;
                        Nege = 0;
                        delay = 2;
                    end                
                    else if ( delay == 2 ) begin
                        Outstr = 16'h8003;
                        delay = 3;                
                    end
                    else begin
                        W_Pointer = W_Pointer + 1;
                        R_Pointer = R_Pointer + 1;
                        delay = 0;
                        Sym_Rec = 0;
                    end      
                end             
            end        
            16'h002B: begin // +
                if ( Sym_Rec == 3 ) begin
                    if ( delay == 0 ) begin
                        Outstr = 16'h7FFF;
                        delay = 1;                
                    end
                    else begin
                        W_Pointer = W_Pointer + 1;
                        R_Pointer = R_Pointer + 1;
                        delay = 0;
                        Sym_Rec = 0;
                    end                
                end
                else begin             
                    if ( delay == 0 ) begin
                        Outstr = Bin_Out;
                        delay = 1;  
                        Decoder_Clr = 1;               
                    end
                    else if ( delay == 1 ) begin
                        W_Pointer = W_Pointer + 1;
                        Decoder_Clk = !Decoder_Clk;
                        Nege = 0;
                        delay = 2;
                    end                
                    else if ( delay == 2 ) begin
                        Outstr = 16'h7FFF;
                        delay = 3;                
                    end
                    else begin
                        W_Pointer = W_Pointer + 1;
                        R_Pointer = R_Pointer + 1;
                        delay = 0;
                        Sym_Rec = 0;
                    end      
                end
            end
            16'h002D: begin // -
                if ( Sym_Rec == 3 ) begin
                    if ( delay == 0 ) begin
                        Outstr = 16'h7FFE;
                        delay = 1;                
                    end
                    else begin
                        W_Pointer = W_Pointer + 1;
                        R_Pointer = R_Pointer + 1;
                        delay = 0;
                        Sym_Rec = 0;
                    end                
                end
                else if ( Sym_Rec == 2 ) begin
                    R_Pointer = R_Pointer + 1;
                    Sym_Rec = 0;
                    Nege = 1;           
                end                
                else begin 
                    if ( delay == 0 ) begin
                        Outstr = Bin_Out;
                        delay = 1;   
                        Decoder_Clr = 1;              
                    end
                    else if ( delay == 1 ) begin
                        W_Pointer = W_Pointer + 1;
                        Decoder_Clk = !Decoder_Clk;
                        Nege = 0;
                        delay = 2;
                    end                
                    else if ( delay == 2 ) begin
                        Outstr = 16'h7FFE;
                        delay = 3;                
                    end
                    else begin
                        W_Pointer = W_Pointer + 1;
                        R_Pointer = R_Pointer + 1;
                        delay = 0;
                        Sym_Rec = 1;
                    end  
                end
            end  
            16'h0028: begin // (               
                if ( delay == 0 ) begin
                    Outstr = 16'h7FFC;
                    delay = 1;                
                end
                else begin
                    W_Pointer = W_Pointer + 1;
                    R_Pointer = R_Pointer + 1;
                    delay = 0;
                    Sym_Rec = 2;
                end        
            end        
            16'h0029: begin // )
                if ( Sym_Rec == 3 ) begin
                    if ( delay == 0 ) begin
                        Outstr = 16'h7FFD;
                        delay = 1;                
                    end
                    else begin
                        W_Pointer = W_Pointer + 1;
                        R_Pointer = R_Pointer + 1;
                        delay = 0;
                        Sym_Rec = 0;
                    end                
                end
                else begin             
                    if ( delay == 0 ) begin
                        Outstr = Bin_Out;
                        delay = 1;  
                        Decoder_Clr = 1;               
                    end
                    else if ( delay == 1 ) begin
                        W_Pointer = W_Pointer + 1;
                        Decoder_Clk = !Decoder_Clk;
                        Nege = 0;
                        delay = 2;
                    end                
                    else if ( delay == 2 ) begin
                        Outstr = 16'h7FFD;
                        delay = 3;                
                    end
                    else begin
                        W_Pointer = W_Pointer + 1;
                        R_Pointer = R_Pointer + 1;
                        delay = 0;
                        Sym_Rec = 3;
                    end
                end             
            end                             
            default: begin  //����
                if ( delay == 0 ) begin
                    Decoder_Clr = 0;
                    delay = 1;                
                end
                else begin
                    Decoder_Clk = !Decoder_Clk;
                    R_Pointer = R_Pointer + 1;
                    delay = 0;
                    Sym_Rec = 0;
                end              
            end      
        endcase
    end
end
endmodule