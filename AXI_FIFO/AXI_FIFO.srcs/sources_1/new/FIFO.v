`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/20 19:45:05
// Design Name: 
// Module Name: FIFO
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FIFO#(   parameter INDATA_WIDTH = 8,
                          OUTDATA_WIDTH = 8,
                          FIFO_DEEP  = 1024//最大深度为65536
             )
            (
                input    i_clk,
                input    rst_n,
                input    i_vaild,
                input    o_clk,
                input    [INDATA_WIDTH-1:0]  din,
                input    i_tlast,
                input    o_tready,     //从设备是否准备好接受数据
                output   i_tready,     //fifo是否准备好接受数据
                output   o_tlast,
                output   reg o_vaild,
                output   reg [OUTDATA_WIDTH-1:0] dout
            );
//计算指针大小的函数
function integer clog2;
    input integer value;
    integer j;
    begin
        clog2 = 0;           // 初始化返回值
        for(j=value-1;j>0;j=j>>1)
        begin
            clog2 = clog2+1'b1;
        end
    end
endfunction

wire full;
wire empty;
reg [INDATA_WIDTH-1:0]memory1[FIFO_DEEP-1:0];
reg [1:0] state;
reg [1:0] next_state;

//状态机状态
localparam [1:0] IDLE   = 'd0,
                 READ   = 'd1,
                 FINISH = 'd2;
//读写数据之间的倍数关系
reg [1:0] DtMr;
localparam [1:0] Half   = 'd0,
                 One    = 'd1,
                 Double = 'd2,
                 Triple = 'd3;
reg [9:0] DATA_NUM;
reg [9:0] DATA_NUM1;
reg [OUTDATA_WIDTH-1:0] dout1;
reg [OUTDATA_WIDTH-1:0] dout2;
//计算读写指针大小
localparam ADDR_WIDTH = clog2(FIFO_DEEP);
reg [ADDR_WIDTH-1:0]wptr;//写指针
reg [ADDR_WIDTH-1:0]wptr1;//写指针
reg [ADDR_WIDTH-1:0]rptr;//读指针
wire [ADDR_WIDTH-1:0]rptr1;//读指针      
reg r_i_tlast;    
reg [1:0]half_word_flag;//判断当前读取的是高位还是低位     
//判断是满还是空
assign full  = (wptr==rptr&&DATA_NUM=='d1)?1'b1:1'b0;
assign empty = (rptr==wptr&&DATA_NUM=='d0)?1'b1:1'b0;
assign rptr1 = (DtMr == Half||DtMr == One)?rptr:
                (DtMr == Double)?(rptr>>1):(rptr>>1-1);
//判断是否可以继续进行写数据状态
assign i_tready= (!full&&o_tready==1'b1)?1'b1:1'b0;
assign o_tlast = (state==FINISH||(DATA_NUM1==1'b0&&rptr==wptr1&&r_i_tlast==1'b1))?1'b1:1'b0;
integer i;
//将输入数据进行缓存
always@(posedge i_clk,negedge rst_n)
begin
    if(!rst_n)
    begin
        wptr <= 'd0;
        wptr1 <= 'd0;
        DATA_NUM1 <= 'd0;
        r_i_tlast <= 'd0;
        for(i=0;i<FIFO_DEEP;i=i+1)
        begin
            memory1[i] <= 'd0;
        end
    end
    else if(state != FINISH)
    begin
        if(!full&&i_vaild&&!i_tlast)
        begin
            wptr <= wptr +1'b1;
            memory1[wptr] <= din;
        end
        else if(i_tlast)
        begin

            wptr1 <= wptr;
            wptr <= wptr +1'b1;
            DATA_NUM1 <= DATA_NUM;
            if(rptr == wptr1)
                r_i_tlast <= 'd0;
            else 
                r_i_tlast <= 'd1;
        end
        else
        begin
            wptr <= wptr;
            memory1[wptr]<=memory1[wptr];
        end
    end
    else 
    begin
          wptr <= 'd0;        
    end
end

always @(posedge i_clk,negedge rst_n) 
begin
    if(!rst_n)
        DATA_NUM<='d0;
    else 
    begin
        if(wptr==FIFO_DEEP)
            DATA_NUM <= DATA_NUM+1'b1;
        else 
            DATA_NUM <= DATA_NUM;
        
    end
end
//判断输入输出数据位宽的关系
always @(*) 
begin
    if(!rst_n)
        DtMr = 'd0;
    else if(OUTDATA_WIDTH==INDATA_WIDTH>>1)
        DtMr = Half;
    else if(OUTDATA_WIDTH==INDATA_WIDTH)
        DtMr = One;
    else if(OUTDATA_WIDTH==INDATA_WIDTH<<1)
        DtMr = Double;
    else 
        DtMr = Triple;
    
end
//状态机进行数据读取
always @(negedge o_clk,negedge rst_n) 
begin
    if(!rst_n)
        state <= IDLE;
    else 
        state <= next_state;      
end

always @(*) 
begin
    case(state)
    IDLE:
    begin
        if(o_tready&&!empty)
            next_state = READ;
        else
            next_state = IDLE;
    end
    READ:
    begin
        if(empty==1'b1)
            next_state = FINISH;
        else 
            next_state = READ;       
    end
    FINISH:
    begin
        next_state = IDLE;
    end
    endcase
end

always @(posedge o_clk,negedge rst_n) 
begin
    if(!rst_n)
    begin
        dout <= 'd0;
        rptr <= 'd0;
        o_vaild <= 'd0;
        half_word_flag <= 'd0;
    end
    else if(state == IDLE)
    begin
        rptr <= rptr;
        dout[rptr] <= dout[rptr];
        o_vaild <= 'd0;
    end
    else if(state == READ)
    begin        
        case(DtMr)
            Half:
            begin
                if(!half_word_flag)
                begin
                    dout <= memory1[rptr][(INDATA_WIDTH-1)-:INDATA_WIDTH>>1];
                    half_word_flag <= 'd1;
                end
                else 
                begin
                    dout <= memory1[rptr][(INDATA_WIDTH>>1)-1:0];
                    rptr  <= rptr+'d1;
                    half_word_flag <= 'd0;
                end 
                o_vaild <= 'd1;             
            end
            One:
            begin
                dout  <= memory1[rptr];
                rptr  <= rptr+'d1;
                o_vaild <= 'd1;
            end
            Double:
            begin
                if(!half_word_flag)
                begin
                    dout[(OUTDATA_WIDTH-1)-:OUTDATA_WIDTH>>1] <= memory1[rptr];
                    half_word_flag <= 'd1;
                    rptr  <= rptr+'d1;
                    o_vaild <= 'd0;
                end
                else 
                begin
                    dout[(OUTDATA_WIDTH>>1)-1:0] <= memory1[rptr];
                    rptr  <= rptr+'d1;
                    half_word_flag <= 'd0;
                    o_vaild <= 'd1;
                end
            end
            Triple:
                if(half_word_flag=='d0)
                begin
                    dout[(OUTDATA_WIDTH-1)-:INDATA_WIDTH] <= memory1[rptr];
                    half_word_flag <= 'd1;
                    rptr  <= rptr+'d1;
                    o_vaild <= 'd0;
                end
                else if(half_word_flag=='d1)
                begin
                    dout[((OUTDATA_WIDTH-INDATA_WIDTH)-1)-:INDATA_WIDTH] <= memory1[rptr];
                    rptr  <= rptr+'d1;
                    half_word_flag <= 'd2;
                    o_vaild <= 'd0;
                end
                else 
                begin
                    dout[((OUTDATA_WIDTH-(INDATA_WIDTH<<1))-1)-:INDATA_WIDTH] <= memory1[rptr];
                    rptr  <= rptr+'d1;
                    half_word_flag <= 'd0;
                    o_vaild <= 'd1;
                end
            default:
            begin
                dout <= 'd0;
                rptr <= 'd0;
                o_vaild <= 'd0;
            end
        endcase
        
        if(rptr==FIFO_DEEP)
        begin
            DATA_NUM <= DATA_NUM -1'b1;  
            DATA_NUM1 <= DATA_NUM1 -1'b1;
        end     
    end
    else 
    begin
        dout <= 'd0;
        rptr <= 'd0;
        o_vaild <= 'd0;      
    end
end

endmodule
