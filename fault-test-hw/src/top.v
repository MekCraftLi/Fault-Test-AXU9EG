`timescale 1ns / 1ps

module top ();

    // BD interface signals
    wire [12:0] bram_addr;
    wire        bram_clk;
    wire [31:0] bram_wr_data;
    wire [31:0] bram_rd_data;
    wire        bram_en;
    wire        bram_rst;
    wire [3:0]  bram_we;
    wire        pl_clk;
    wire [0:0]  pl_rst;

    // FI Control signals from bram_ctrl
    wire [31:0] execution_cyc_length;
    wire [31:0] inject_cycle;
    wire [7:0]  ia_upper;
    wire [31:0] ia_lower;
    wire        icap_grant;
    wire        icap_sel;
    wire        inject_enable;
    wire        inject_strobe;
    wire        mask_exp;
    wire        mask_inj;
    wire        halt_from_processor;
    wire        gsr;
    wire        reset_rtl;
    wire        sem_clk_en;
    wire        continue_run;

    // FI Status signals to bram_ctrl
    wire        expired_cycle;
    wire        dut_clock_stopped;
    wire        error;
    wire [31:0] current_cycle;
    wire        injection_cycle_reached;
    wire        status_injection;

    // Filter DUT data signals
    wire [7:0]  i_data_real;
    wire [7:0]  i_data_imag;
    wire [17:0] filtRslt_real;
    wire [17:0] filtRslt_imag;

    // FIM clock
    wire        dutclk;

    // SEM signals
    wire        status_heartbeat;
    wire        status_initialization;
    wire        status_observation;
    wire        status_correction;
    wire        status_classification;
    wire        status_diagnostic_scan;
    wire        status_detect_only;
    wire        status_essential;
    wire        status_uncorrectable;

    wire        command_strobe;
    wire        command_busy;
    wire [43:0] command_code;

    wire        cap_req;
    wire        inject_strobe_pulse;

    // 1. Block Design Instance
    axi_bus_wrapper bd_inst (
        .BRAM_PORTA_0_addr(bram_addr),
        .BRAM_PORTA_0_clk(bram_clk),
        .BRAM_PORTA_0_din(bram_wr_data),
        .BRAM_PORTA_0_dout(bram_rd_data),
        .BRAM_PORTA_0_en(bram_en),
        .BRAM_PORTA_0_rst(bram_rst),
        .BRAM_PORTA_0_we(bram_we),
        .pl_clk(pl_clk),
        .pl_rst(pl_rst)
    );

    // 2. BRAM Control Module (addr-shiyan register map)
    bram_ctrl bram_ctrl_inst (
        .BRAM_PORTA_rst(bram_rst),
        .BRAM_PORTA_clk(bram_clk),
        .BRAM_PORTA_addr({3'b000, bram_addr}),
        .BRAM_PORTA_din(bram_wr_data),
        .BRAM_PORTA_dout(bram_rd_data),
        .BRAM_PORTA_en(bram_en),
        .BRAM_PORTA_we(bram_we),

        .execution_cyc_length(execution_cyc_length),
        .inject_cycle(inject_cycle),
        .ia_upper(ia_upper),
        .ia_lower(ia_lower),
        .icap_grant(icap_grant),
        .icap_sel(icap_sel),
        .inject_enable(inject_enable),
        .inject_strobe(inject_strobe),
        .mask_exp(mask_exp),
        .mask_inj(mask_inj),
        .halt_from_processor(halt_from_processor),
        .gsr(gsr),
        .reset_rtl(reset_rtl),
        .sem_clk_en(sem_clk_en),
        .continue_run(continue_run),

        .expired_cycle(expired_cycle),
        .dut_clock_stopped(dut_clock_stopped),
        .error(error),
        .current_cycle(current_cycle),
        .inject_cycle_reached(injection_cycle_reached),
        .status_injection(status_injection),
        .status_initialization(status_initialization),
        .status_observation(status_observation),
        .command_busy(command_busy),
        .status_heartbeat(status_heartbeat),
        .status_correction(status_correction),
        .status_classification(status_classification),
        .status_essential(status_essential),
        .status_uncorrectable(status_uncorrectable),

        .testprj_result_addr(),
        .testprj_rd_en(),
        .testprj_rd_dat(32'h0),

        .i_data_real(i_data_real),
        .i_data_imag(i_data_imag),
        .filtRslt_real(filtRslt_real),
        .filtRslt_imag(filtRslt_imag),

        .fifo_din(),
        .fifo_din_vld(),
        .fifo_rd_en(),
        .fifo_cnt(8'h0),
        .fifo_dout(8'h0)
    );

    // 3. Command generation for UltraScale+ SEM
    level2pulse l2p_inject (
        .clk(pl_clk),
        .level(inject_strobe),
        .pulse(inject_strobe_pulse)
    );

    assign command_strobe = inject_strobe_pulse & inject_enable;
    // UltraScale+ SEM command format:
    // command_code[43:40] = ia_upper[7:4] (0xE=Idle, 0xC=Inject, 0xA=Observation, 0xB=Reset)
    // command_code[39:0]  = {ia_upper[3:0], 4'b0000, ia_lower[31:0]}
    assign command_code = {ia_upper[7:4], ia_upper[3:0], 4'b0000, ia_lower[31:0]};

    // 4. UltraScale+ SEM Controller & ICAPE3 Primitive
    sem_ultra_0_support sem_support_inst (
        .icap_clk(pl_clk),

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

        .uart_tx(),
        .uart_rx(1'b1),

        .command_strobe(command_strobe),
        .command_busy(command_busy),
        .command_code(command_code),

        .cap_rel(1'b0),
        .cap_gnt(1'b1),
        .cap_req(cap_req),

        .aux_error_cr_ne(1'b0),
        .aux_error_cr_es(1'b0),
        .aux_error_uc(1'b0)
    );

    // 5. Fault Injection Manager (FIM) with BUFGCE Clock Gating
    (* DONT_TOUCH = "TRUE" *)
    fim #(32) fim_inst (
        .clk(pl_clk),
        .reset(reset_rtl),
        .haltfromprocessor(halt_from_processor),
        .MaskInj(mask_inj),
        .MaskExp(mask_exp),
        .continue_run(continue_run),
        .turbo_clk_cnt_en(1'b1),
        .injectcycle(inject_cycle),
        .executioncyclelength(execution_cyc_length),
        .error(error),
        .cycles_expired(expired_cycle),
        .injection_cycle_reached(injection_cycle_reached),
        .dut_clk(dutclk),
        .dut_clk_stopped(dut_clock_stopped),
        .currentcycle(current_cycle)
    );

    // 6. Isolated Filter DUT constrained to pblock_TESTMODULE
    (* DONT_TOUCH = "TRUE" *)
    filter TESTMODULE (
        .prj_clk(dutclk),
        .prj_rst_n(~reset_rtl),
        .i_data_real($signed(i_data_real)),
        .i_data_imag($signed(i_data_imag)),
        .o_data_real(filtRslt_real),
        .o_data_imag(filtRslt_imag)
    );

endmodule
