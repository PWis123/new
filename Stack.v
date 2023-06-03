//ͨ�ö�ջģ��
module  Stack(
input clk,      // ����������ջ����
input rst_n,
input pop,
input push,
input [15:0] datain,
output reg [15:0] dataout,
output reg [15:0] Top,
output reg empty,
output reg full
);
    
reg [15:0] r_stack[255:0];
reg [7:0] sp = 0;           //0��255�Ķ�ջָ��

    //���ݳ����߼�
    always@( clk ) begin
        if ( !rst_n ) begin
            sp <= 16'd0;
        end
        else begin
            if ( push && !pop ) begin
                if ( sp < 255 ) begin
                    r_stack[sp] <= datain;
                    sp <= sp + 1;
                end
            end
            else if ( !push && pop ) begin
                if ( sp != 16'd0 ) begin
                    dataout <= r_stack[ sp - 1 ];
                    sp <= sp - 1;
                end
            end
            else;
        end
    end
    
    //��ջָ���߼�
    always@(*) begin
        if ( !rst_n ) begin
            full <= 0;
            empty <= 0;
        end
        else begin
            if ( sp == 0 ) begin
                empty <= 1;
                full <= 0;
            end
            else if ( sp == 255 ) begin
                full <= 1;
                empty <= 0;
            end
            else begin
                full <= 0;
                empty <= 0;
            end
        end
    end
    
    //ջ�����������Ҫʹ��pop��
    always@(*) begin
        Top = r_stack[sp - 1];
    end

endmodule




