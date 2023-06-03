//4位ASCII码转16位二进制
module ASCII_2_Num_Decoder(
Decoder_Clr, Decoder_Clk, Nege,
ASCII_In, Bin_Out
);
input wire Decoder_Clr;     //为0时同步清零
input wire Decoder_Clk;     //译码器时钟
input wire [7:0] ASCII_In;  //输入的ASCII码
input wire Nege;            //负数输出
output reg [15:0] Bin_Out;  //二进制数输出

reg [15:0] Bin_Out_temp = 0;
reg [31:0] ASCII_Seq = 32'h30303030;

//-----------------------------------------------------------------------
//数据移位
    always @( Decoder_Clk ) begin 
        if ( ~Decoder_Clr )    
            ASCII_Seq = ASCII_Seq<<8 | ASCII_In;
        else
            ASCII_Seq = 32'h30303030;
    end   


//-----------------------------------------------------------------------
//译码
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