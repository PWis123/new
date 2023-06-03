module VGA_typewriter #(
        parameter H_RES = 640,
        parameter V_RES = 480,
        parameter SCALE = 8, //choose from 1,2,4,5,8,10
        parameter CHARA_WIDTH = 8,  
        parameter CHARA_HEIGHT = 11,
        parameter GRID_COL = H_RES/(CHARA_WIDTH*SCALE),
        parameter GRID_ROW = V_RES/(CHARA_HEIGHT*SCALE),  
        parameter ADDR_WIDTH = 11,                
        parameter ASCII_WIDTH = 8
    )(
        input  clk_50m,     // 50 MHz clock
        input  rst,    // reset button
        input [3:0] colorIndexF,
        input [3:0] colorIndexB,
        input [7:0] asciiWrite,
        input dataReady,
        output vga_hsync,    // horizontal sync
        output vga_vsync,    // vertical sync
        output [3:0] vga_r,  // 4-bit VGA red
        output [3:0] vga_g,  // 4-bit VGA green
        output [3:0] vga_b,   // 4-bit VGA blue
        input [5:0] addrRead,
        output [7:0] asciiRead
    );
    
    // generate pixel clock
    wire clk_pix;
    wire clk_pix_locked;
    wire [ASCII_WIDTH-1:0] asciiWrite;
    wire writeEn;

    
    
    clk_wiz_0 clock_pix_inst (
       clk_pix,
       rst,  // reset button is active low
       clk_pix_locked,
       clk_50m  // not used for VGA output
    );

    wire rst_n = clk_pix_locked;  // wait for clock lock

    wire [11:0] vga;
    assign vga = {vga_r,vga_g,vga_b};
    
    dispLogic #(
        .GRID_ROW(GRID_ROW),
        .GRID_COL(GRID_COL),
        .ASCII_WIDTH(ASCII_WIDTH), 
        .ADDR_WIDTH(ADDR_WIDTH),
        .CHARA_WIDTH(CHARA_WIDTH), 
        .CHARA_HEIGHT(CHARA_HEIGHT),
        .SCALE(SCALE)
    )Display (
        clk_pix,
        rst_n,
        colorIndexF,
        colorIndexB,
        asciiWrite,
        dataReady,
        vga_hsync,  
        vga_vsync,  
        vga,
        addrRead,
        asciiRead
    );
 
endmodule

module dispLogic #(
    parameter GRID_ROW = 5,
    parameter GRID_COL = 10,
    parameter ASCII_WIDTH = 8,
    parameter BUFFER_WIDTH = 16,
    parameter ADDR_WIDTH = 11,
    parameter CHARA_WIDTH = 8,  
    parameter CHARA_HEIGHT = 11,
    parameter CORDW = 16,
    parameter SCALE = 8
    )(
    input clk_pix,
    input rst_n,
    input [(BUFFER_WIDTH-ASCII_WIDTH)/2-1:0] colorIndexF,
    input [(BUFFER_WIDTH-ASCII_WIDTH)/2-1:0] colorIndexB,
    input [ASCII_WIDTH-1:0] asciiWrite,
    input dataReady,
    output vga_hsync,    // horizontal sync
    output vga_vsync,    // vertical sync
    output reg [11:0] vga,  // 12-bit VGA color
    input [5:0] addrRead,
    output [7:0] asciiRead    
    );
    
    wire dataEnable;
    wire frameStart;
    wire lineStart;
    wire signed [CORDW - 1:0] sx;
    wire signed [CORDW - 1:0] sy;   
    wire hsync,vsync; 
    display_480p #(
        .SCALE(SCALE),
        .CHARA_WIDTH(CHARA_WIDTH),
        .CHARA_HEIGHT(CHARA_HEIGHT),
        .GRID_ROW(GRID_ROW),
        .GRID_COL(GRID_COL)
    ) display_inst(
        clk_pix,
        rst_n,
        vga_hsync,
        vga_vsync,
        dataEnable,
        frameStart,
        lineStart,
        sx,
        sy
    );
       
    reg [$clog2(GRID_COL)-1:0] chPos_x = 0;
    reg [$clog2(GRID_ROW)-1:0] chPos_y = 0;
    wire [15:0] charBundle;    
    dispBuffer #(
        BUFFER_WIDTH,
        ASCII_WIDTH,
        GRID_ROW,
        GRID_COL
    ) displayBuffer(
        clk_pix,
        rst_n,
        chPos_x,
        chPos_y,
        dataReady,
        asciiWrite,
        colorIndexF,
        colorIndexB,
        charBundle,
        addrRead,
        asciiRead
    );
    
    wire [3:0] bitCnt;
    wire [3:0] lineCnt;
    wire x_tick;
    wire y_tick;
     
    magnifier #(
        SCALE,
        CHARA_WIDTH,
        CHARA_HEIGHT,
        CORDW
    ) charaMagnifier(
        rst_n,
        dataEnable,
        sx,
        sy,
        bitCnt,
        lineCnt,
        x_tick,
        y_tick
    );    
 
    wire [ADDR_WIDTH-1:0] charaLineAddr;
    asciiDec #(
        ASCII_WIDTH, 
        ADDR_WIDTH,
        CHARA_HEIGHT
    ) asciiDecLogic(
        charBundle[7:0],
        lineCnt,
        charaLineAddr
    );      
              
    wire [CHARA_WIDTH-1:0] charaLine;                                                               
    charaROM #(
        CHARA_WIDTH,
        ADDR_WIDTH 
    ) charrom(
        charaLineAddr,
        charaLine
    );                      
    
    wire [11:0] charColor;
    wire [11:0] backColor;
    CLUT backCLUT(charBundle[15:12],backColor);    
    CLUT charCLUT(charBundle[11:8],charColor);

    always@( posedge bitCnt == 0 or negedge rst_n) begin
        if(!rst_n) begin
            chPos_x <= 0;
        end        
        else if( dataEnable ) begin
            if( chPos_x == GRID_COL - 1 ) begin
                chPos_x <= 0;
            end
            else begin
                chPos_x <=  chPos_x + 1 ;             
            end
        end
    end
    
    always@( posedge lineCnt == 0 or negedge rst_n) begin
        if(!rst_n) begin
            chPos_y <= 0;
        end            
        else if( dataEnable ) begin
            if( chPos_y == GRID_ROW - 1 ) begin
                chPos_y <= 0;
            end
            else begin
                chPos_y <=  chPos_y + 1 ;             
            end
        end
    end   
                  
    always@(posedge clk_pix or negedge rst_n) begin
        if(!rst_n) begin
            vga <= 12'h0;
        end
        else if ( dataEnable ) begin
            if ( charaLine[bitCnt] ) begin
                vga <= charColor;
            end
            else begin
                vga <= backColor;
            end
        end
        else begin
            vga <= 12'h0;
        end
    end                          
    
                    
endmodule 

module display_480p #(
        parameter CORDW = 16,
        parameter H_RES = 640,
        parameter V_RES = 480,
        parameter H_FP = 16,
        parameter H_SYNC = 96,
        parameter H_BP = 48,
        parameter V_FP = 10,
        parameter V_SYNC = 2,
        parameter V_BP = 33,
        parameter H_POL = 0,
        parameter V_POL = 0,
        parameter H_OFFSET = 1,
        parameter SCALE = 8,
        parameter CHARA_WIDTH = 8,
        parameter CHARA_HEIGHT = 11,
        parameter GRID_ROW = 5,
        parameter GRID_COL = 10,
        parameter signed  H_STA = -((H_FP + H_SYNC) + H_BP),
        parameter signed  V_STA = -((V_FP + V_SYNC) + V_BP)
 )(
        input wire clk_pix,                
        input wire rst_n,                
        output reg hsync = 1,                 
        output reg vsync = 1,                  
        output reg de = 0,                     
        output reg frame = 0,                  
        output reg line = 0,                   
        output reg signed [CORDW - 1:0] sx = H_STA,
        output reg signed [CORDW - 1:0] sy = V_STA
);
        
        localparam signed  HS_STA = H_STA + H_FP;
        localparam signed  HS_END = HS_STA + H_SYNC;
        localparam signed  HA_STA = 0;
        localparam signed  HA_END = H_RES - 1;
        
        localparam signed  VS_STA = V_STA + V_FP;
        localparam signed  VS_END = VS_STA + V_SYNC;
        localparam signed  VA_STA = 0;
        localparam signed  VA_END = V_RES - 1;
                
        always @(posedge clk_pix or negedge rst_n) begin
                if (!rst_n) begin
                        hsync <= (H_POL ? 0 : 1);
                        vsync <= (V_POL ? 0 : 1);
                end
                else begin                
                        hsync <= (H_POL ? (sx > HS_STA) && (sx <= HS_END) : ~((sx > HS_STA) && (sx <= HS_END)));
                        vsync <= (V_POL ? (sy > VS_STA) && (sy <= VS_END) : ~((sy > VS_STA) && (sy <= VS_END)));
                end
        end
        always @(posedge clk_pix or negedge rst_n) begin
                if (!rst_n) begin
                        de <= 0;
                        frame <= 0;
                        line <= 0;
                end
                else begin                
                        de <= (sy >= VA_STA && sy < CHARA_HEIGHT*SCALE*GRID_ROW) && (sx >= HA_STA && sx < CHARA_WIDTH*SCALE*GRID_COL);
                        frame <= (sy == V_STA) && (sx == H_STA);
                        line <= sx == H_STA;
                end
        end
        always @(posedge clk_pix or negedge rst_n) begin
                if (!rst_n) begin
                        sx <= H_STA;
                        sy <= V_STA;
                end                
                else if (sx == HA_END) begin
                        sx <= H_STA;
                        sy <= (sy == VA_END ? V_STA : sy + 1);
                end
                else
                        sx <= sx + 1;
        end

endmodule

 module dispBuffer #(
    parameter BUFFER_WIDTH = 16,
    parameter ASCII_WIDTH = 8,
    parameter GRID_ROW = 5,
    parameter GRID_COL = 10
    ) (
    input clk_pix,
    input rst_n,
    input [$clog2(GRID_COL)-1:0] chPos_x,
    input [$clog2(GRID_ROW)-1:0] chPos_y,
    input dataReady,
    input [ASCII_WIDTH-1:0] ascii,
    input [(BUFFER_WIDTH-ASCII_WIDTH)/2-1:0] colorIndexF,
    input [(BUFFER_WIDTH-ASCII_WIDTH)/2-1:0] colorIndexB,
    output reg [BUFFER_WIDTH-1:0] bufferBundle,
    input [5:0] addrRead,
    output [7:0] asciiRead
    ); 
    integer i;

    (* dont_touch = "true" *)reg [BUFFER_WIDTH-1:0] Buffer [GRID_COL*GRID_ROW-1:0];
    reg [BUFFER_WIDTH-1:0] cursorTemp = 0; 
    reg [$clog2(GRID_COL*GRID_ROW)-1:0] wrPos;
    
    always@(posedge dataReady or negedge rst_n) begin
        if(!rst_n) begin
            for(i=1; i<GRID_COL*GRID_ROW; i=i+1) begin
                 Buffer[i] <= {colorIndexB,colorIndexF,8'd0};  
            end
            wrPos <= 0; 
            Buffer[wrPos] <= {colorIndexB,colorIndexF,8'd127}; 
            cursorTemp <= {colorIndexB,colorIndexF,8'd0};     
        end
        else if(ascii==8'b00010001) begin  //left
            Buffer[wrPos] <= cursorTemp;
            cursorTemp <= Buffer[wrPos==0 ? GRID_COL*GRID_ROW-1 : wrPos-1];        
            Buffer[wrPos==0 ? GRID_COL*GRID_ROW-1 : wrPos-1] <= {colorIndexB,colorIndexF,8'd127};
            wrPos <= wrPos==0 ? GRID_COL*GRID_ROW-1 : wrPos-1 ;            
        end
        else if(ascii==8'b00010100) begin  //right
            Buffer[wrPos] <= cursorTemp;
            cursorTemp <= Buffer[wrPos==GRID_COL*GRID_ROW-1 ? 0 : wrPos+1];        
            Buffer[wrPos==GRID_COL*GRID_ROW-1 ? 0 : wrPos+1] <= {colorIndexB,colorIndexF,8'd127};
            wrPos <= wrPos==GRID_COL*GRID_ROW-1 ? 0 : wrPos+1;            
        end
        else if(ascii==8'b00010010) begin  //up
            Buffer[wrPos] <= cursorTemp;
            cursorTemp <= Buffer[wrPos>=GRID_COL ? wrPos-GRID_COL : wrPos+(GRID_ROW-1)*GRID_COL];        
            Buffer[wrPos>=GRID_COL ? wrPos-GRID_COL : wrPos+(GRID_ROW-1)*GRID_COL] <= {colorIndexB,colorIndexF,8'd127};
            wrPos <= wrPos>=GRID_COL ? wrPos-GRID_COL : wrPos+(GRID_ROW-1)*GRID_COL;            
        end
        else if(ascii==8'b00010011) begin  //down
            Buffer[wrPos] <= cursorTemp;
            cursorTemp <= Buffer[wrPos<(GRID_ROW-1)*GRID_COL ? wrPos+GRID_COL : wrPos-(GRID_ROW-1)*GRID_COL];        
            Buffer[wrPos<(GRID_ROW-1)*GRID_COL ? wrPos+GRID_COL : wrPos-(GRID_ROW-1)*GRID_COL] <= {colorIndexB,colorIndexF,8'd127};
            wrPos <= wrPos<(GRID_ROW-1)*GRID_COL ? wrPos+GRID_COL : wrPos-(GRID_ROW-1)*GRID_COL;            
        end 
        else if(ascii==8'b00001101) begin  //enter
            Buffer[wrPos] <= cursorTemp;
            cursorTemp <= Buffer[ wrPos<(GRID_ROW-1)*GRID_COL ? ((wrPos/GRID_COL)+1)*GRID_COL : 0 ];        
            Buffer[ wrPos<(GRID_ROW-1)*GRID_COL ? ((wrPos/GRID_COL)+1)*GRID_COL : 0 ] <= {colorIndexB,colorIndexF,8'd127};
            wrPos <= wrPos<(GRID_ROW-1)*GRID_COL ? ((wrPos/GRID_COL)+1)*GRID_COL : 0 ;            
        end 
        else if(ascii==8'b01111111) begin //backSpace
            Buffer[wrPos] <= {colorIndexB,colorIndexF,8'd0};
            cursorTemp <= {colorIndexB,colorIndexF,8'd0};        
            Buffer[wrPos==0 ? GRID_COL*GRID_ROW-1 : wrPos-1] <= {colorIndexB,colorIndexF,8'd127};
            wrPos <= wrPos==0 ? GRID_COL*GRID_ROW-1 : wrPos-1 ;                        
        end        
        else begin
            Buffer[wrPos] <= {colorIndexB,colorIndexF,ascii};
            wrPos <= wrPos<GRID_COL*GRID_ROW-1 ? wrPos + 1 : 0;
            Buffer[ wrPos==GRID_COL*GRID_ROW-1 ? 0 : wrPos+1 ] <= {colorIndexB,colorIndexF,8'd127};
        end
    end                  

    always@(posedge clk_pix or negedge rst_n) begin
        if(!rst_n) begin
            bufferBundle <= 16'b0;
        end
        else begin
            bufferBundle <= Buffer[chPos_x + GRID_COL*chPos_y];
        end
    end
    
    assign asciiRead = Buffer[addrRead];
    
endmodule

module magnifier#(
    parameter SCALE = 8,
    parameter CHARA_WIDTH = 8,
    parameter CHARA_HEIGHT = 11,
    parameter CORDW = 16
    )(
    input rst_n,
    input de,
    input signed [CORDW - 1:0] sx,
    input signed [CORDW - 1:0] sy,
    output reg [3:0] bitCnt,
    output reg [3:0] lineCnt,
    output reg x_tick,
    output reg y_tick 
    );

    always@ (*) begin
        x_tick <= sx % SCALE == SCALE - 1;
        y_tick <= sy % SCALE == SCALE - 1;
    end

    always@(posedge x_tick or negedge rst_n) begin
        if(!rst_n) begin
            bitCnt <= 0;
        end                
        else if(de) begin
            bitCnt <= bitCnt == CHARA_WIDTH -1 ? 0 : bitCnt + 4'b1 ;      
        end
    end
    

    always@(posedge y_tick or negedge rst_n) begin
        if(!rst_n) begin
            lineCnt <= 0;
        end                 
        else if(de) begin   
            lineCnt <= lineCnt == CHARA_HEIGHT -1 ? 0 : lineCnt + 4'b1 ;
        end
    end
       
    
endmodule

module asciiDec #(
    parameter ASCII_WIDTH = 8,
    parameter ADDR_WIDTH = 11,
    parameter CHARA_HEIGHT = 11
    )(
    input [ASCII_WIDTH-1:0] ascii,
    input [3:0] lineCnt,
    output reg [ADDR_WIDTH-1:0] charaLineAddr
    );
    
    always@(*) begin
        if(ascii <= 31 || ascii > 127) begin
            charaLineAddr <= 11'b0;
        end
        else begin
            charaLineAddr <= (ascii - 32) * 11 + lineCnt;
        end
    end
    
    
endmodule

module charaROM #(
    parameter CHARA_WIDTH = 8,
    parameter ADDR_WIDTH = 11
    )(
    input [ADDR_WIDTH-1:0] addr,
    output [CHARA_WIDTH-1:0] charaLine
    );
    
    reg [CHARA_WIDTH-1:0] charaROM [1044:0];
   
    initial
        $readmemh("ascii.mem", charaROM,0,1044);
        
    assign charaLine = charaROM [addr];
    
endmodule

module CLUT(
    input [3:0] index,
    output [11:0] color
    );
    
    reg [11:0] CLUT [15:0];
    
    assign color = CLUT [index];
    
    initial begin
        $readmemh("sweetie16_4b.mem", CLUT);
    end
    
endmodule





