module TOPTOP(
    input clk_50m,
    input rst,
    
    //VGA & exKeyboard parts
    input [3:0] colorIndexF,
    input [3:0] colorIndexB,
    input [7:0] keyCode,
    input dataReady,
    output vga_hsync,    // horizontal sync
    output vga_vsync,    // vertical sync
    output [3:0] vga_r,  // 4-bit VGA red
    output [3:0] vga_g,  // 4-bit VGA green
    output [3:0] vga_b,   // 4-bit VGA blue
    output [11:0] led
    
    );


    wire [5:0] addrRead;
    wire [7:0] asciiRead; 
    wire [7:0] asciiWrite;  
    VGA_typewriter VGA(
        clk_50m,
        rst,
        colorIndexF,
        colorIndexB,
        asciiWrite,
        dataReady,
        vga_hsync,
        vga_vsync,
        vga_r,
        vga_g,
        vga_b,
        led,
        addrRead,
        asciiRead
        );   
    

//    wire calcStart = (asciiWrite == 8'b00001101) & dataReady;
    wire Finish;          //ÕÍ≥…º∆À„
    wire [15:0] Result;    
    Calculator_Top calculator(
        clk_50m,
        asciiWrite,
        addrRead,
        Finish,
        Result,
        rst
        ); 
        
    
    
    
    
    exKeyIn xKey(
       keyCode,
       asciiWrite
    );


   
    
endmodule
