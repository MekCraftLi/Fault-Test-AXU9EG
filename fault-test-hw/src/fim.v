`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/17/2017 12:14:34 PM
// Design Name: 
// Module Name: fim
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


module fim #(parameter countwidth=32) (
clk,reset,haltfromprocessor,MaskInj,MaskExp,injectcycle,executioncyclelength,continue_run,turbo_clk_cnt_en,
error,cycles_expired,injection_cycle_reached,dut_clk,dut_clk_stopped,currentcycle);
input clk;
input reset;
input haltfromprocessor;
//input[dutwidth-1:0] comp_inp1;
//input[dutwidth-1:0] comp_inp2;
input MaskInj;
input MaskExp;
input[countwidth-1:0] injectcycle;
input[countwidth-1:0] executioncyclelength;
input  continue_run  ;
input  turbo_clk_cnt_en;
output error;
output cycles_expired;
output injection_cycle_reached;
output dut_clk;
output dut_clk_stopped;
output[countwidth-1:0] currentcycle;
assign error = 1'b0;
(* dont_touch = "true" *)CEM #(countwidth) cem_inst(
         .clk(clk),
         .reset(reset),
         .haltfromprocessor(haltfromprocessor),
         .injmask(MaskInj),
         .expmask(MaskExp),
         .injectcycle(injectcycle),
         .exe_cycle_length(executioncyclelength),
		 .continue_run  (continue_run  ), //input
		 .turbo_clk_cnt_en(turbo_clk_cnt_en), //input
         .error_detected_level(error),
         .current_dut_cycle(currentcycle),
         .dut_ce_flag(dut_clk_stopped),
         .dut_cycles_expired_flag(cycles_expired),
         .dut_injection_cycle_reached_flag(injection_cycle_reached),
         .dut_clk(dut_clk)
         );
         
//(* dont_touch = "true" *)CEG #(dutwidth) ceg_inst(
//        .clk(clk),
//        .reset(reset),
//        .input1(comp_inp1),
//        .input2(comp_inp2),
//        .detected_level(error)
//        );

endmodule
