/////////////////////////////////////////////////////////////////////////////
//
//
//
/////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /
// \   \   \/    Core:          sem_ultra
//  \   \        Module:        sem_ultra_0_support
//  /   /        Filename:      sem_ultra_0_support.v
// /___/   /\    Purpose:       Support layer for the IP.
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
// This module contains the instantiation of the SEM controller, configuration 
// system primitives, and helper blocks integral to the system level solution 
// of the IP.
//
/////////////////////////////////////////////////////////////////////////////
//
// Port Definition:
//
// Name                          Type   Description
// ============================= ====== ====================================
// icap_clk                      input  Globally routed system clock.  Used
//                                      to drive ICAP, controller and all
//                                      other modules.
//
// status_heartbeat              output Heartbeat signal for external watch
//                                      dog timer implementation; pulses
//                                      when readback runs.  Synchronous to
//                                      icap_clk.
//
// status_initialization         output Indicates initialization is taking
//                                      place.  Synchronous to icap_clk.
//
// status_observation            output Indicates observation is taking
//                                      place.  Synchronous to icap_clk.
//
// status_correction             output Indicates correction is taking
//                                      place.  Synchronous to icap_clk.
//
// status_classification         output Indicates classification is taking
//                                      place.  Synchronous to icap_clk.
//
// status_injection              output Indicates injection is taking
//                                      place.  Synchronous to icap_clk.
//
// status_diagnostic_scan        output Indicates diagnostic scan
//                                      command is taking place.
//                                      Synhronous to icap_clk.
//
// status_detect_only            output Indicates detect-only scan 
//                                      command is taking place.
//                                      Synhronous to icap_clk.
//
// status_essential              output Indicates essential error condition.
//                                      Qualified by de-assertion of the
//                                      status_classification signal, and
//                                      is synchronous to icap_clk.
//
// status_uncorrectable          output Indicates uncorrectable error
//                                      condition. Qualified by de-assertion
//                                      of the status_correction signal, and
//                                      is synchronous to icap_clk.
//
// uart_tx                       output UART status output.  Synchronous
//                                      to icap_clk, but received externally
//                                      by another device as an asynchronous
//                                      signal, perceived as lower bitrate.
//                                      Uses 8N1 protocol.
//
// uart_rx                       input  UART command input.  Asynchronous
//                                      signal provided by another device at
//                                      a lower bitrate, synchronized to the
//                                      icap_clk and oversampled.  Uses 8N1
//                                      protocol.
//
// command_strobe                input  Command strobe signal, used to 
//                                      capture command_code.  Pulse for
//                                      one cycle.  Synchronous to icap_clk.
//
// command_busy                  output Command busy signal, used to 
//                                      indicate the command port is 
//                                      unavailable.  Synchronous to icap_clk.
//
// command_code[43:0]            input  Command input bus.  Synchronous to
//                                      icap_clk.
//
// cap_gnt                       input  ICAP arbitration input for the
//                                      controller to receive permission
//                                      to access the external ICAP.
//                                      Synchronous to icap_clk.
//
// cap_req                      output  ICAP arbitration output for the
//                                      controller to request access to the
//                                      external ICAP. Synchronous to icap_clk.
//
// cap_rel                       input  ICAP arbitration input for the
//                                      controller to receive request 
//                                      for access of the external ICAP.
//                                      Synchronous to icap_clk. 
//
// aux_error_cr_ne              input   Auxiliary correctable non-essential error
//                                      indication.
//
//
// aux_error_cr_es              input   Auxiliary correctable essential error
//                                      indication. 
//
//
// aux_error_cr_uc              input   Auxiliary uncorrectable error  
//                                      indication.
//
/////////////////////////////////////////////////////////////////////////////
//
// Module Dependencies:
//
// sem_ultra_0_support
// |
// +- sem_ultra_0           (SEM controller)
// |
// +- sem_ultra_0_cfg       
// |
// +- sem_ultra_0_uart 
   
//
/////////////////////////////////////////////////////////////////////////////

`timescale 1 ps / 1 ps

/////////////////////////////////////////////////////////////////////////////
// Module
/////////////////////////////////////////////////////////////////////////////

module sem_ultra_0_support (
  input  wire        icap_clk,

// Status interface
  output wire        status_heartbeat,
  output wire        status_initialization,
  output wire        status_observation,
  output wire        status_correction,
  output wire        status_classification,
  output wire        status_injection,
  output wire        status_diagnostic_scan,
  output wire        status_detect_only,  
  output wire        status_essential,
  output wire        status_uncorrectable,

// UART interface
  output wire        uart_tx,
  input  wire        uart_rx,

// Command interface
  input  wire        command_strobe,
  output wire        command_busy,
  input  wire [43:0] command_code,

// ICAP arbitration interface
  input  wire        cap_rel,
  input  wire        cap_gnt,
  output wire        cap_req,

// Auxiliary interface
  input  wire        aux_error_cr_ne,
  input  wire        aux_error_cr_es,
  input  wire        aux_error_uc
  );

  ///////////////////////////////////////////////////////////////////////////
  // Define local constants.
  ///////////////////////////////////////////////////////////////////////////

  localparam TCQ = 1;

  ///////////////////////////////////////////////////////////////////////////
  // Internal signals.
  ///////////////////////////////////////////////////////////////////////////
  wire       icap_clk_i;

  wire [31:0] icap_o;
  wire        icap_csib;
  wire        icap_rdwrb;
  wire [31:0] icap_i;
  wire        icap_prerror;
  wire        icap_prdone;
  wire        icap_avail;

  wire        fecc_eccerrornotsingle;
  wire        fecc_eccerrorsingle;
  wire        fecc_endofframe;
  wire        fecc_endofscan;
  wire        fecc_crcerror;
  wire [26:0] fecc_far;
  wire  [1:0] fecc_farsel;

  wire  [7:0] monitor_txdata;
  wire        monitor_txwrite;
  wire        monitor_txfull;
  wire  [7:0] monitor_rxdata;
  wire        monitor_rxread;
  wire        monitor_rxempty;


  assign icap_clk_i = icap_clk;

  ///////////////////////////////////////////////////////////////////////////
  // Instantiate the SEM controller. The controller sub-module is the kernel 
  // of the soft error mitigation solution.  The port list is dynamic based 
  // on the IP core options selected from the Vivado IP GUI.
  ///////////////////////////////////////////////////////////////////////////

   sem_ultra_0
   sem_controller
  (
    .status_heartbeat(status_heartbeat),
    .status_initialization(status_initialization),
    .status_observation(status_observation),
    .status_correction(status_correction),
    .status_classification(status_classification),
    .status_injection(status_injection),
    .status_diagnostic_scan(status_diagnostic_scan),
    .status_detect_only(status_detect_only),
    .status_essential(status_essential),
    .status_uncorrectable(status_uncorrectable),
    .monitor_txdata(monitor_txdata),
    .monitor_txwrite(monitor_txwrite),
    .monitor_txfull(monitor_txfull),
    .monitor_rxdata(monitor_rxdata),
    .monitor_rxread(monitor_rxread),
    .monitor_rxempty(monitor_rxempty),
    .command_strobe(command_strobe),
    .command_busy(command_busy),
    .command_code(command_code),
    .icap_clk(icap_clk_i),
    .icap_o(icap_o),
    .icap_csib(icap_csib),
    .icap_rdwrb(icap_rdwrb),
    .icap_i(icap_i),
    .icap_prerror(icap_prerror),
    .icap_prdone(icap_prdone),
    .icap_avail(icap_avail),
    .cap_rel(cap_rel),
    .cap_gnt(cap_gnt),
    .cap_req(cap_req),
    .fecc_eccerrornotsingle(fecc_eccerrornotsingle),
    .fecc_eccerrorsingle(fecc_eccerrorsingle),
    .fecc_endofframe(fecc_endofframe),
    .fecc_endofscan(fecc_endofscan),
    .fecc_crcerror(fecc_crcerror),
    .fecc_far(fecc_far),
    .fecc_farsel(fecc_farsel),
    .aux_error_cr_ne(aux_error_cr_ne),
    .aux_error_cr_es(aux_error_cr_es),
    .aux_error_uc(aux_error_uc));

  ///////////////////////////////////////////////////////////////////////////
  // Instantiate the configuration module.
  ///////////////////////////////////////////////////////////////////////////

  sem_ultra_0_cfg example_cfg (
    .icap_clk(icap_clk_i),
    .icap_o(icap_o),
    .icap_csib(icap_csib),
    .icap_rdwrb(icap_rdwrb),
    .icap_i(icap_i),
    .icap_prerror(icap_prerror),
    .icap_prdone(icap_prdone),
    .icap_avail(icap_avail),
    .fecc_eccerrornotsingle(fecc_eccerrornotsingle),
    .fecc_eccerrorsingle(fecc_eccerrorsingle),
    .fecc_endofframe(fecc_endofframe),
    .fecc_endofscan(fecc_endofscan),
    .fecc_crcerror(fecc_crcerror),
    .fecc_far(fecc_far),
    .fecc_farsel(fecc_farsel));

  ///////////////////////////////////////////////////////////////////////////
  // Instantiate the UART helper block. 
  ///////////////////////////////////////////////////////////////////////////

  sem_ultra_0_uart example_uart (
    .icap_clk(icap_clk_i),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx),
    .monitor_txdata(monitor_txdata),
    .monitor_txwrite(monitor_txwrite),
    .monitor_txfull(monitor_txfull),
    .monitor_rxdata(monitor_rxdata),
    .monitor_rxread(monitor_rxread),
    .monitor_rxempty(monitor_rxempty));


endmodule

/////////////////////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////////////////////
