`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/20/2017 08:46:07 AM
// Design Name: 
// Module Name: genflag
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


module genflag #(parameter COUNTER_WIDTH=32)(current_dut_cycle,exe_cycle_length,injectcycle,injmask,expmask,error_detected_level,haltfromprocessor_pulse,
dut_cycles_expired_flag,dut_injection_cycle_reached_flag,dut_ce_flag,continue_run);
input [COUNTER_WIDTH-1:0] current_dut_cycle;
input  [COUNTER_WIDTH-1:0] injectcycle;
input  [COUNTER_WIDTH-1:0] exe_cycle_length;
input  injmask;
input  expmask;
input  error_detected_level;
input haltfromprocessor_pulse;
input continue_run  ;
output dut_ce_flag;
output dut_cycles_expired_flag;
output dut_injection_cycle_reached_flag;
wire halt;

assign dut_cycles_expired_flag = (current_dut_cycle==exe_cycle_length);
assign dut_injection_cycle_reached_flag = (current_dut_cycle == injectcycle);
assign halt = ((dut_injection_cycle_reached_flag & injmask) | (dut_cycles_expired_flag & expmask) | ~(haltfromprocessor_pulse | continue_run)) ;
assign dut_ce_flag = ~halt;
endmodule
