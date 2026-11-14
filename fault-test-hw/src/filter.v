`timescale 1ps/1ps

module filter#(
	parameter	INWIDTH = 8,
	parameter	OUTWIDTH= 18,
	parameter	TAPS = 4,
	parameter	H_REAL = {-8'd1,8'd11,8'd123,-8'd6},
	parameter	H_IMAG = {TAPS*INWIDTH{1'b0}}
)(
	input								prj_clk		,
	input								prj_rst_n	,
	input		signed	[INWIDTH-1:0]	i_data_real	,
	input		signed	[INWIDTH-1:0]	i_data_imag	,
	output	reg	signed	[OUTWIDTH-1:0]	o_data_real	,
	output	reg	signed	[OUTWIDTH-1:0]	o_data_imag	 
);

localparam	MULT_WIDTH = INWIDTH*2;
reg		signed	[OUTWIDTH-1:0]		acc_real	[0:TAPS-2];
reg		signed	[OUTWIDTH-1:0]		acc_imag	[0:TAPS-2];

wire	signed	[MULT_WIDTH-1:0]	mult_rslt_real	[0:TAPS-1]	;
wire	signed	[MULT_WIDTH-1:0]	mult_rslt_imag	[0:TAPS-1]	;

genvar	i;
genvar	j;
for(i=0; i<TAPS; i=i+1) begin:	MULTGENERATE
	complexMult #(.AWIDTH(INWIDTH),
				  .BWIDTH(INWIDTH))
		mult (
			.i_A_real	(H_REAL[(i+1)*INWIDTH-1:i*INWIDTH]	)	, //input	signed	[AWIDTH-1:0]		
			.i_A_imag	(H_IMAG[(i+1)*INWIDTH-1:i*INWIDTH]	)	, //input	signed	[AWIDTH-1:0]		
			.i_B_real	(i_data_real						)	, //input	signed	[BWIDTH-1:0]		
			.i_B_imag	(i_data_imag						)	, //input	signed	[BWIDTH-1:0]		
			.o_C_real	(mult_rslt_real[TAPS-i-1]			)	, //output	signed	[AWIDTH+BWIDTH-1:0]	
			.o_C_imag	(mult_rslt_imag[TAPS-i-1]			)      //output	signed	[AWIDTH+BWIDTH-1:0]	
		);
end

always @(posedge prj_clk or negedge prj_rst_n) begin
	if(!prj_rst_n) 
		acc_real[0] <= {OUTWIDTH{1'b0}};
	else 
		acc_real[0] <= mult_rslt_real[TAPS-1];
end

always @(posedge prj_clk or negedge prj_rst_n) begin
	if(!prj_rst_n) 
		acc_imag[0] <= {OUTWIDTH{1'b0}};
	else 
		acc_imag[0] <= mult_rslt_imag[TAPS-1];
end

for(j=1; j<TAPS-1; j=j+1) begin:	ACCGENERATE
	always @(posedge prj_clk or negedge prj_rst_n) begin
		if(!prj_rst_n) 
			acc_real[j] <= {OUTWIDTH{1'b0}};
		else
			acc_real[j] <= acc_real[j-1] + mult_rslt_real[TAPS-j-1];
	end
	
	always @(posedge prj_clk or negedge prj_rst_n) begin
		if(!prj_rst_n) 
			acc_imag[j] <= {OUTWIDTH{1'b0}};
		else
			acc_imag[j] <= acc_imag[j-1] + mult_rslt_imag[TAPS-j-1];
	end
	
end

always @(posedge prj_clk or negedge prj_rst_n) begin
	if(!prj_rst_n) 
		o_data_real <= {OUTWIDTH{1'b0}};
	else
		o_data_real <= acc_real[TAPS-2] + mult_rslt_real[0];
end

always @(posedge prj_clk or negedge prj_rst_n) begin
	if(!prj_rst_n) 
		o_data_imag <= {OUTWIDTH{1'b0}};
	else
		o_data_imag <= acc_imag[TAPS-2] + mult_rslt_imag[0];
end

endmodule
