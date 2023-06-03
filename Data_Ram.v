//RAMÊý¾Ý¶Î
module Data_Ram(
    input           clk,
    input           we,    
    input  [7:0]    addr,
    input  [15:0]   write_data,    
    output [15:0]   read_data
);

    reg [15:0] RAM[127:0];    
    assign read_data = RAM[addr[7:0]];      
    always@(posedge clk)
    if(we)
        RAM[addr[7:0]] <= write_data;    
endmodule