`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/07/2017 04:58:59 PM
// Design Name: 
// Module Name: level2pulse
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


//module level2pulse(clk,level,pulse);
//input clk;
//input level;
//output pulse;
//reg level_reg;
//always@(posedge clk) begin
//    level_reg <= level;
//end
//assign pulse = level & ~level_reg; 
//endmodule

// 011产生一个单周期的脉冲
module level2pulse(clk,level,pulse);
input clk;
input level;
output pulse;
reg s0;
reg s1;
wire s0_p;
wire s1_p;
always@(negedge clk)//modify posedge clk to negedge clk
begin
       s0 <= s0_p;
       s1 <= s1_p;
end 
assign s0_p = level;
assign s1_p = level & s0;
assign pulse = s0 & ~s1;
endmodule