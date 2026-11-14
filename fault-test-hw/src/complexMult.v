`timescale 1ps/1ps

module complexMult#(
	parameter	AWIDTH = 8,
	parameter	BWIDTH = 8
)(
	input	signed	[AWIDTH-1:0]	i_A_real	,
	input	signed	[AWIDTH-1:0]	i_A_imag	,
	input	signed	[BWIDTH-1:0]	i_B_real	,
	input	signed	[BWIDTH-1:0]	i_B_imag	,
	output	signed	[AWIDTH+BWIDTH-1:0]	o_C_real,
	output	signed	[AWIDTH+BWIDTH-1:0]	o_C_imag 
);

assign	o_C_real = i_A_real*i_B_real - i_A_imag*i_B_imag;
assign	o_C_imag = i_A_real*i_B_imag + i_A_imag*i_B_real;

endmodule
