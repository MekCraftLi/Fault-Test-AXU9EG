`timescale 1ns / 1ps

module my_bram_reg (
    input wire clk,
    input wire rst,

    input  wire        bram_en,
    input  wire [ 3:0] bram_we,
    input  wire [12:0] bram_addr,
    input  wire [31:0] data_in,
    output reg  [31:0] data_out,

    // SEM signals
    output wire [39:0] inject_address,
    output wire        inject_strobe,

    input  wire        status_injection,
    input  wire        status_observation,
    input  wire        status_correction,

    // Filter DUT interface
    output wire [7:0]  filt_data_real,
    output wire [7:0]  filt_data_imag,
    input  wire [17:0] filt_rslt_real,
    input  wire [17:0] filt_rslt_imag
);

    wire [7:0] reg_index = bram_addr[9:2];

    reg  [31:0] registers [63:0];

    assign inject_address = {registers[1][7:0], registers[0]};
    assign inject_strobe  = registers[2][0];

    assign filt_data_real = registers[32][7:0];
    assign filt_data_imag = registers[33][7:0];

    integer i;

    always @(posedge clk) begin
        if (rst == 1'b1) begin
            for (i = 0; i < 64; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (bram_en == 1'b1 && bram_we == 4'b1111) begin
            if (reg_index != 3 && reg_index < 64) begin
                registers[reg_index] <= data_in;
            end
        end
    end

    always @(posedge clk) begin
        if (rst == 1'b1) begin
            data_out <= 32'b0;
        end else if (bram_en == 1'b1 && bram_we == 4'b0000) begin
            case (reg_index)
                8'd0:    data_out <= registers[0];
                8'd1:    data_out <= registers[1];
                8'd2:    data_out <= registers[2];
                8'd3:    data_out <= {29'b0, status_correction, status_observation, status_injection};
                8'd32:   data_out <= registers[32];
                8'd33:   data_out <= registers[33];
                8'd34:   data_out <= {{14{filt_rslt_real[17]}}, filt_rslt_real};
                8'd35:   data_out <= {{14{filt_rslt_imag[17]}}, filt_rslt_imag};
                default: data_out <= (reg_index < 64) ? registers[reg_index] : 32'b0;
            endcase
        end
    end

endmodule
