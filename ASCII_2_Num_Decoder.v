//4λASCII��ת16λ������
module ASCII_2_Num_Decoder(
Decoder_Clr, Decoder_Clk, Nege,
ASCII_In, Bin_Out
);
input wire Decoder_Clr;     //Ϊ0ʱͬ������
input wire Decoder_Clk;     //������ʱ��
input wire [7:0] ASCII_In;  //�����ASCII��
input wire Nege;            //�������
output reg [15:0] Bin_Out;  //�����������

reg [15:0] Bin_Out_temp = 0;
reg [31:0] ASCII_Seq = 32'h30303030;

//-----------------------------------------------------------------------
//������λ
    always @( Decoder_Clk ) begin 
        if ( ~Decoder_Clr )    
            ASCII_Seq = ASCII_Seq<<8 | ASCII_In;
        else
            ASCII_Seq = 32'h30303030;
    end   


//-----------------------------------------------------------------------
//����
    always @(*)begin
        Bin_Out_temp = ASCII_Seq [ 7 : 0 ] - 48 + ((ASCII_Seq [ 15 : 8 ] - 48 ) << 1 ) + ((ASCII_Seq [15 : 8 ] - 48 ) << 3 ) +
               ((ASCII_Seq [ 23 : 16 ] - 48 ) << 2 ) + ((ASCII_Seq [ 23 : 16 ] - 48 ) << 5 ) + ((ASCII_Seq [ 23 : 16 ] - 48 ) << 6 ) +
               ((ASCII_Seq [ 31 : 24 ] - 48 ) << 3 ) + ((ASCII_Seq [ 31 : 24 ] - 48 ) << 5 ) + ((ASCII_Seq [ 31 : 24 ] - 48 ) << 6 ) +
               ((ASCII_Seq [ 31 : 24 ] - 48 ) << 7 ) + ((ASCII_Seq [ 31 : 24 ] - 48 ) << 8 ) + ((ASCII_Seq [ 31 : 24 ] - 48 ) << 9 );
        if ( Nege )
            Bin_Out = ~Bin_Out_temp + 1;
        else 
            Bin_Out = Bin_Out_temp;
    end
         
endmodule