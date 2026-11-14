/////////////////////////////////////////////////////////////////////////////
//
//
//
/////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /
// \   \   \/    Core:          sem_ultra
//  \   \        Module:        sem_ultra_0_cfg
//  /   /        Filename:      sem_ultra_0_cfg.v
// /___/   /\    Purpose:       Wrapper file for configuration logic.
// \   \  /  \
//  \___\/\___\
//
/////////////////////////////////////////////////////////////////////////////
//
// (c) Copyright 2014-2020 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES. 
//
/////////////////////////////////////////////////////////////////////////////
//
// Module Description:
//
// This module is a wrapper to encapsulate the FRAME_ECC and ICAP primitives.
//
/////////////////////////////////////////////////////////////////////////////
//
// Port Definition:
//
// Name                          Type   Description
// ============================= ====== ====================================
// icap_clk                      input  The controller clock, used to clock
//                                      the configuration logic as well.
//
// icap_o[31:0]                  output ICAP data output.  Synchronous to
//                                      icap_clk.
//
// icap_csib                     input  ICAP chip select, active low.  Used
//                                      to enable the ICAP for read or write.
//                                      Synchronous to icap_clk.
//
// icap_rdwrb                    input  ICAP write select, active low.  Used
//                                      to select between read or write.
//                                      Synchronous to icap_clk.
//
// icap_i[31:0]                  input  ICAP data input.  Synchronous to
//                                      icap_clk.
//
// icap_prerror                  output ICAP Partial Reconfiguration error, 
//                                      active high. Synchronous to icap_clk.
//
// icap_prdone                   output ICAP Partial Reconfiguration complete, 
//                                      active high. Synchronous to icap_clk.
//
// icap_avail                    output ICAP available, active high.  Used
//                                      to indicate that the ICAP can be 
//                                      utilized.  Synchronous to icap_clk.
//
// fecc_eccerrnotsingle          output FRAME_ECC status indicating multiple
//                                      -bit ECC errors detected within the
//                                      frame.  Synchronous to icap_clk.
//
// fecc_eccerrorsingle           output FRAME_ECC status indicating a 
//                                      single-bit ECC error detected in a 
//                                      frame.  Synchronous to icap_clk.
//
// fecc_endofframe               output FRAME_ECC signal that will pulse
//                                      for one cycle at end of each frame
//                                      read. Synchronous to icap_clk.
//
// fecc_endofscan                output FRAME_ECC signal that will pulse
//                                      for one cycle at end of each round 
//                                      of SEU scan. Synchronous to icap_clk.
//
// fecc_crcerror                 output FRAME_ECC status indicating CRC 
//                                      mismatch error detected.  Synchronous
//                                      to icap_clk.
//
// fecc_far[26:0]                output FRAME_ECC status showing FAR or EFAR.
//                                      Synchronous to icap_clk.
//
// fecc_farsel[1:0]               input FRAME_ECC mux selection to FAR
//                                      Frame Address output.  Synchronous
//                                      to icap_clk.
//
/////////////////////////////////////////////////////////////////////////////
//
// Parameter and Localparam Definition:
//
// Name                          Type   Description
// ============================= ====== ====================================
// TCQ                           int    Sets the clock-to-out for behavioral
//                                      descriptions of sequential logic.
//
/////////////////////////////////////////////////////////////////////////////
//
// Module Dependencies:
//
// sem_ultra_0_cfg
// |
// +- ICAPE3 (unisim)
// |
// \- FRAME_ECCE4 (unisim)
//
/////////////////////////////////////////////////////////////////////////////

`timescale 1 ps / 1 ps

/////////////////////////////////////////////////////////////////////////////
// Module
/////////////////////////////////////////////////////////////////////////////

module sem_ultra_0_cfg (
  input  wire        icap_clk,
  output wire [31:0] icap_o,
  input  wire        icap_csib,
  input  wire        icap_rdwrb,
  input  wire [31:0] icap_i,
  output wire        icap_prerror,
  output wire        icap_prdone,
  output wire        icap_avail,
  output wire        fecc_eccerrornotsingle,
  output wire        fecc_eccerrorsingle,
  output wire        fecc_endofframe,
  output wire        fecc_endofscan,
  output wire        fecc_crcerror,
  output wire [26:0] fecc_far,
  input  wire  [1:0] fecc_farsel
  );

  ///////////////////////////////////////////////////////////////////////////
  // Define local constants.
  ///////////////////////////////////////////////////////////////////////////

  localparam TCQ = 1;

  ///////////////////////////////////////////////////////////////////////////
  // Instantiate the configuration primitives.
  ///////////////////////////////////////////////////////////////////////////

  ICAPE3 #(
    .DEVICE_ID(32'hffffffff))
  cfg_icape3 (
    .PRERROR(icap_prerror),
    .PRDONE(icap_prdone),
    .AVAIL(icap_avail),
    .O(icap_o),
    .I(icap_i),
    .CSIB(icap_csib),
    .RDWRB(icap_rdwrb),
    .CLK(icap_clk));

  FRAME_ECCE4 cfg_frame_ecce4 (
    .ICAPTOPCLK(icap_clk),
    .ICAPBOTCLK(),
    .ECCERRORNOTSINGLE(fecc_eccerrornotsingle),
    .ECCERRORSINGLE(fecc_eccerrorsingle),
    .ENDOFFRAME(fecc_endofframe),
    .ENDOFSCAN(fecc_endofscan),
    .CRCERROR(fecc_crcerror),
    .FAR(fecc_far),
    .FARSEL(fecc_farsel));

  ///////////////////////////////////////////////////////////////////////////
  //
  ///////////////////////////////////////////////////////////////////////////

endmodule

/////////////////////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////////////////////
