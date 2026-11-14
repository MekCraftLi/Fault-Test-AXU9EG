`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/17/2017 04:45:16 PM
// Design Name: 
// Module Name: dutcyclecounter
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


module dutcyclecounter #(parameter width=32)(clk,reset,turbo_clk_cnt_en,currentcycle);
input clk;
input reset;
input turbo_clk_cnt_en;
output reg[width-1:0] currentcycle;
always @(posedge clk)
begin   
    if (reset)
        currentcycle <= {width{1'b0}};
    else if(turbo_clk_cnt_en)begin   //modified by yt in 20191219
        currentcycle <= currentcycle + 1'b1; 
     end
end 
endmodule
