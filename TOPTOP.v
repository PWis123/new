module TOPTOP(
    input clk_50m,
    input rst_n,
    
    //VGA & exKeyboard parts
    input [3:0] colorIndexF,
    input [3:0] colorIndexB,
    input [7:0] keyCode,
    input dataReady_keyBoard,
    output vga_hsync,    // horizontal sync
    output vga_vsync,    // vertical sync
    output [3:0] vga_r,  // 4-bit VGA red
    output [3:0] vga_g,  // 4-bit VGA green
    output [3:0] vga_b,   // 4-bit VGA blue
    output [11:0] led
    
    );
    wire [7:0] asciiWrite_keyBoard;  
    wire dataReady_result;           
    wire [7:0] asciiWrite_result;  
    reg dataReady;
    reg [7:0] asciiWrite;
     
    wire [5:0] addrRead;
    wire [7:0] asciiRead; 
    
    reg Fin = 0;
    VGA_typewriter VGA(
        clk_50m,
        rst_n,
        colorIndexF,
        colorIndexB,
        asciiWrite,
        dataReady,
        vga_hsync,
        vga_vsync,
        vga_r,
        vga_g,
        vga_b,
        addrRead,
        asciiRead
        );   
    

    wire calcStart = (asciiWrite == 8'b00001101) & dataReady;
    wire Finish;          //ÕÍ≥…º∆À„
    wire [15:0] Result;    
    Calculator_Top calculator(
        clk_50m,
        asciiRead,
        calcStart,
        rst_n,
        addrRead,
        Finish,
        Result
        ); 
        
    always@(*) begin
        if ( Finish == 1 && Fin == 0 )
            Fin = 1;
    end    
    assign led = {3'd0,Fin,Result[7:0]};
    
    
    wire bcd_done;
    reg resultTransfer;
    wire [3:0] tenK;
    wire [3:0] thou;
    wire [3:0] hund;
    wire [3:0] tens;
    wire [3:0] ones;
    
    bin2BCD bin2bcd(
        clk_50m,
        rst_n,
        Finish,
        Result,     
        bcd_done,
        tenK,
        thou,
        hund,
        tens,
        ones
    );
    
    always @(posedge bcd_done or negedge rst_n) begin
        if(!rst_n)
            resultTransfer <= 0;
        else
            resultTransfer <= 1;
    end
    
        
    BCD2ASCII bcd2ascii(
        clk_50m,
        rst_n,
        bcd_done,
        tenK,  
        thou,
        hund,
        tens,
        ones,
        dataReady_result,
        asciiWrite_result
        );
        
    always @ (*) begin
        if(resultTransfer == 0) begin
            dataReady <= dataReady_keyBoard;
            asciiWrite <= asciiWrite_keyBoard;
        end
        else if(resultTransfer == 1) begin
            dataReady <= dataReady_result;  
            asciiWrite <= asciiWrite_result;
        end
    end
    
    exKeyIn xKey(
       keyCode,
       asciiWrite_keyBoard
    );


   
    
endmodule
