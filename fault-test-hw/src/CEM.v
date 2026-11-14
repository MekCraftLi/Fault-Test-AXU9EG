`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/03/2017 01:19:13 PM
// Design Name: 
// Module Name: up_counter
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


module CEM #(parameter COUNTER_WIDTH=32)(
clk,reset,haltfromprocessor,injmask,expmask,injectcycle,exe_cycle_length,continue_run,turbo_clk_cnt_en,
error_detected_level,current_dut_cycle,dut_ce_flag,dut_cycles_expired_flag,dut_injection_cycle_reached_flag,dut_clk);
input  clk;
input  reset;
input haltfromprocessor;
input  injmask;
input  expmask;
input error_detected_level;
input  [COUNTER_WIDTH-1:0] injectcycle;
input  [COUNTER_WIDTH-1:0] exe_cycle_length;
input  continue_run  ;
input  turbo_clk_cnt_en;
output [COUNTER_WIDTH-1:0] current_dut_cycle;
output dut_ce_flag;
output dut_cycles_expired_flag;
output dut_injection_cycle_reached_flag;
output dut_clk;
wire haltfromprocessor_pulse;
//reg continue_run_reg;

genflag #(32) genflag_i(
      .current_dut_cycle(current_dut_cycle),
      .exe_cycle_length(exe_cycle_length),
      .injectcycle(injectcycle),
      .injmask(injmask),
      .expmask(expmask),
      .error_detected_level(error_detected_level),
      .haltfromprocessor_pulse(haltfromprocessor_pulse),
	  .continue_run  (continue_run  ), //input 
      .dut_cycles_expired_flag(dut_cycles_expired_flag),
      .dut_injection_cycle_reached_flag(dut_injection_cycle_reached_flag),
      .dut_ce_flag(dut_ce_flag)
      );

  BUFGCE BUFGCE_inst (
     .O(dut_clk),   // 1-bit output: Clock output
     .CE(dut_ce_flag), // 1-bit input: Clock enable input for I0
     .I(clk)    // 1-bit input: Primary clock
  );
  
(* dont_touch = "true" *) dutcyclecounter #(32) cc(
         .clk(dut_clk),
         .reset(reset),
         .turbo_clk_cnt_en(turbo_clk_cnt_en),
         .currentcycle(current_dut_cycle)
         ); 
         
level2pulse l2p(clk,haltfromprocessor,haltfromprocessor_pulse);

//always @(negedge clk)begin
//    continue_run_reg <= continue_run;
//end

endmodule
