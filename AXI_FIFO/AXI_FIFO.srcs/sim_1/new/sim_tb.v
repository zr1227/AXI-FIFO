`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/20 23:01:18
// Design Name: 
// Module Name: sim_tb
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


module sim_tb();
 parameter INDATA_WIDTH  = 8;
 parameter OUTDATA_WIDTH = 24;
 parameter FIFO_DEEP     = 1024;
 reg i_clk;
 reg rst_n;
 reg i_vaild;
 reg o_clk;
 reg [INDATA_WIDTH-1:0]din;
 reg i_tlast;
 reg o_tready;
 wire i_tready;
 wire o_tlast;
 wire o_vaild;
 wire [OUTDATA_WIDTH-1:0] dout;

FIFO#(
        .INDATA_WIDTH(INDATA_WIDTH),
        .OUTDATA_WIDTH(OUTDATA_WIDTH),
        .FIFO_DEEP(FIFO_DEEP)
) f1
(
        .i_clk(i_clk),
        .rst_n(rst_n),
        .i_vaild(i_vaild),
        .o_clk(o_clk),
        .din(din),
        .i_tlast(i_tlast),
        .o_tready(1'b1),
        .i_tready(i_tready),
        .o_tlast(o_tlast),
        .o_vaild(o_vaild),
        .dout(dout)
);

initial
begin
    i_clk = 'd0;
    rst_n = 'd0;
    i_vaild = 'd0;
    i_tlast = 'd0;
    o_tready = 'd0;
    din<='d0;
    i_vaild<='d0;
    o_clk = 'd0;
#10;
    rst_n = 'd1;
#10;
    o_tready = 'd1;
end
reg [10:0]count;
always@(posedge i_clk,negedge rst_n)
begin
    if(!rst_n)
        count<='d0;
    else if(count<='d1023)
    begin
        count<=count+1'b1;
        din<=din+1'b1;
        i_vaild<='d1;
        if(count == 'd511)
            i_tlast <= 'd1;
        else 
            i_tlast <= 'd0;
    end
    else
    begin
        i_vaild<='d0;
        din<='d0;
        count<=count;
    end
end

always #5 i_clk = ~i_clk;
always #20 o_clk = ~o_clk;
endmodule
