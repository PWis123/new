module bin2BCD#(
    parameter       DATA_WIDTH  =   16,
    parameter       SHIFT_WIDTH =   5,
    parameter       SHIFT_DEPTH =   16
    
    )(
        input               clk,
        input               rst_n,
        input               tran_en,
        input       [DATA_WIDTH - 1:0]  data_in,
        output   reg        tran_done,
        output      [3:0]   tenK_data,
        output      [3:0]   thou_data,      //千位
        output        [3:0]    hund_data,      //百位
        output        [3:0]    tens_data,      //十位
        output        [3:0]    unit_data       //个位

    );
//-------------------------------------------------------
    localparam  IDLE    =   3'b001;
    localparam   SHIFT   =   3'b010;
    localparam   DONE    =   3'b100;

    //-------------------------------------------------------
    reg     [2:0]   pre_state;
    reg     [2:0]   next_state;
    //
    reg     [SHIFT_DEPTH-1:0]   shift_cnt;
    //
    reg     [DATA_WIDTH:0]  data_reg;
    reg     [3:0]   tenK_reg;
    reg     [3:0]   thou_reg;
    reg        [3:0]    hund_reg;
    reg        [3:0]    tens_reg;
    reg        [3:0]    unit_reg; 
    reg     [3:0]   tenK_out;
    reg     [3:0]   thou_out;
    reg        [3:0]    hund_out;
    reg        [3:0]    tens_out;
    reg        [3:0]    unit_out; 
    wire    [3:0]   tenK_tmp;
    wire    [3:0]   thou_tmp;
    wire    [3:0]    hund_tmp;
    wire    [3:0]    tens_tmp;
    wire    [3:0]    unit_tmp;

    //-------------------------------------------------------
    //FSM step1
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0)begin
            pre_state <= IDLE;
        end
        else begin
            pre_state <= next_state;
        end
    end

    //FSM step2
    always  @(*)begin
        case(pre_state)
        IDLE:begin
            if(tran_en == 1'b1)
                next_state = SHIFT;
            else 
                next_state = IDLE;
        end
        SHIFT:begin
            if(shift_cnt == SHIFT_DEPTH + 1)
                next_state = DONE;
            else 
                next_state = SHIFT;
        end
        DONE:begin
            next_state = IDLE;
        end
        default:next_state = IDLE;
        endcase
    end

    //FSM step3
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0)begin
            tenK_reg <= 4'b0;
            thou_reg <= 4'b0; 
            hund_reg <= 4'b0; 
            tens_reg <= 4'b0; 
            unit_reg <= 4'b0; 
            tran_done <= 1'b0;
            shift_cnt <= 'd0; 
            data_reg <= 'd0;
        end
        else begin
            case(next_state)
            IDLE:begin
                tenK_reg <= 4'b0;
                thou_reg <= 4'b0; 
                hund_reg <= 4'b0; 
                tens_reg <= 4'b0; 
                unit_reg <= 4'b0; 
                tran_done <= 1'b0;
                shift_cnt <= 'd0; 
                data_reg <= data_in;
            end
            SHIFT:begin
                if(shift_cnt == SHIFT_DEPTH + 1)
                    shift_cnt <= 'd0;
                else begin
                    shift_cnt <= shift_cnt + 1'b1;
                    data_reg <= data_reg << 1;
                    unit_reg <= {unit_tmp[2:0], data_reg[16]};
                    tens_reg <= {tens_tmp[2:0], unit_tmp[3]};
                    hund_reg <= {hund_tmp[2:0], tens_tmp[3]};
                    thou_reg <= {thou_tmp[2:0], hund_tmp[3]};
                    tenK_reg <= {tenK_tmp[2:0], thou_tmp[3]};
                end
            end
            DONE:begin
                tran_done <= 1'b1;
            end
            default:begin
                tenK_reg <= tenK_reg;
                thou_reg <= thou_reg; 
                hund_reg <= hund_reg; 
                tens_reg <= tens_reg; 
                unit_reg <= unit_reg; 
                tran_done <= tran_done;
                shift_cnt <= shift_cnt; 
            end
            endcase
        end
    end
    //-------------------------------------------------------
    always  @(posedge clk or negedge rst_n)begin
        if(rst_n == 1'b0)begin
            tenK_out <= 'd0;
            thou_out <= 'd0;
            hund_out <= 'd0;
            tens_out <= 'd0;
            unit_out <= 'd0; 
        end
        else if(tran_done == 1'b1)begin
            tenK_out <= tenK_reg;
            thou_out <= thou_reg;
            hund_out <= hund_reg;
            tens_out <= tens_reg;
            unit_out <= unit_reg;
        end
        else begin
            tenK_out <= tenK_out;
            thou_out <= thou_out;
            hund_out <= hund_out;
            tens_out <= tens_out;
            unit_out <= unit_out;
        end
    end


    //-------------------------------------------------------
    assign  tenK_tmp = (tenK_reg > 4'd4)?  (tenK_reg + 2'd3) : tenK_reg;
    assign  thou_tmp = (thou_reg > 4'd4)?  (thou_reg + 2'd3) : thou_reg;
    assign  hund_tmp = (hund_reg > 4'd4)?  (hund_reg + 2'd3) : hund_reg;
    assign  tens_tmp = (tens_reg > 4'd4)?  (tens_reg + 2'd3) : tens_reg; 
    assign  unit_tmp = (unit_reg > 4'd4)?  (unit_reg + 2'd3) : unit_reg; 

    assign tenK_data = tenK_out;
    assign thou_data = thou_out;
    assign hund_data = hund_out;
    assign tens_data = tens_out;
    assign unit_data = unit_out;


endmodule  

module BCD2ASCII(
    input clk,
    input rst_n,
    input start,
    input [3:0] tenK,  
    input [3:0] thou,
    input [3:0] hund,
    input [3:0] tens,
    input [3:0] ones,
    output dataReady,
    output reg [7:0] ascii
    );

    wire [3:0] BCD [4:0];
    assign BCD[4] = ones;
    assign BCD[3] = tens;
    assign BCD[2] = hund;
    assign BCD[1] = thou;
    assign BCD[0] = tenK;

    reg [2:0] i;
    reg printFlag;
    reg startFlag;
    reg endFlag;
    reg pulse_tmp;
    reg s;
    reg clk_div = 0;
    reg [15:0] cnt;

    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt <= 16'b0;
        end
        else if(cnt < 16'd10) begin
            cnt <= cnt + 1'b1;
        end
        else if(cnt == 16'd10) begin
            cnt <= 16'b0;
            clk_div <= ~clk_div;
        end
    end

    always @(negedge start or negedge rst_n) begin
        if(!rst_n) begin
            startFlag <= 0;
        end
        else if(!start) begin
            startFlag <= 1;
        end
    end


    always @(posedge clk_div or negedge rst_n) begin
        if(!rst_n) begin
            i <= 3'b0;
            ascii <= 8'b0;
            printFlag <= 0;
            endFlag <= 0;
            s <= 0;
        end
        else if(startFlag == 1 & printFlag == 0 & endFlag == 0) begin
            if(BCD[i] == 4'b0) begin
                i <= i + 1'b1;
            end
            else begin
                printFlag <= 1;
            end
        end
        else if(startFlag == 1 & printFlag == 1 & endFlag == 0) begin
            ascii <= {4'h3,BCD[i]};
            s <= ~s;
            i <= i + 1'b1;
            if(i > 4) begin
                endFlag <= 1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pulse_tmp <= 1'b0;
        end
        else begin
            pulse_tmp <= s;
        end
    end

   assign dataReady = !(pulse_tmp ^ s);

endmodule










