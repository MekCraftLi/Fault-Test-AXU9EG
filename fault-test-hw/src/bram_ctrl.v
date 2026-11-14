`timescale	1ps/1ps

module bram_ctrl(
	input					BRAM_PORTA_rst	,
	input					BRAM_PORTA_clk	,
	input			[15:0]	BRAM_PORTA_addr	,
	input			[31:0]	BRAM_PORTA_din	,
	output			[31:0]	BRAM_PORTA_dout	,
	input					BRAM_PORTA_en	,
	input			[3 :0]	BRAM_PORTA_we	,
	
	output  reg  	[31:0]	execution_cyc_length,
	output  reg  	[31:0]	inject_cycle		,
	output  reg  	[7 :0]	ia_upper			,
	output  reg  	[31:0]	ia_lower            ,
	output  reg   			icap_grant  		,
	output  reg   			icap_sel            ,
	output  reg   			inject_enable    	,
	output  reg   			inject_strobe		,
	output  reg   			mask_exp            ,
	output  reg   			mask_inj            ,
	output  reg   			halt_from_processor	,
	output  reg   			gsr					,
	output  reg   			reset_rtl			,
	output  reg   			sem_clk_en			,
	output  reg   			continue_run  		,
	input			   		expired_cycle		,
	input			   		dut_clock_stopped	,
	input			   		error				,
	input	        [31:0]	current_cycle		,
	input			   		inject_cycle_reached,
	input			   		status_injection	,
	input			   		status_initialization,
	input			   		status_observation ,
	input			   		command_busy        ,
	input			   		status_heartbeat    ,
	input			   		status_correction   ,
	input			   		status_classification,
	input			   		status_essential    ,
	input			   		status_uncorrectable,
	
	output          [7:0]  testprj_result_addr  ,//
	output                 testprj_rd_en        ,//
    input           [31:0] testprj_rd_dat       ,//
    
    output  reg     [8-1:0] i_data_real         ,     
    output  reg     [8-1:0] i_data_imag         ,  
    input           [18-1:0]filtRslt_real       ,
    input           [18-1:0]filtRslt_imag       ,
    

    output  reg     [ 7:0]  fifo_din           ,
    output  reg             fifo_din_vld       ,
  
    output  wire            fifo_rd_en         ,
    input   wire    [ 7:0]  fifo_cnt           ,
    input   wire    [ 7:0]  fifo_dout        
    
    
);
wire	rst = BRAM_PORTA_rst;
wire	clk = BRAM_PORTA_clk;

reg				testprj_rd_en_d1;
reg             cpu_rd_en_d1    ;
wire [ 7:0]     cpu_addr        ;
reg  [ 7:0]     cpu_addr_d1     ;

wire			cpu_ce		    ;
wire			cpu_we		    ;
wire			cpu_rd_en       ;
reg		[15:0]	cpu_rd_add      ;
reg		[31:0]	cpu_rdata	    ;
wire   [31:0]   cpu_wdata       ;
reg             status_injection_latch;

localparam      VERSION   = 32'h20200306;

assign	testprj_result_addr = BRAM_PORTA_addr[9:2];	//8bit:0-255

assign	testprj_rd_en = (BRAM_PORTA_en==1'b1) 
						&& (BRAM_PORTA_addr[15:10]==1'b1) 
						&& (BRAM_PORTA_addr[1:0]==2'd0) 
						&& (BRAM_PORTA_we==4'b0);

assign	cpu_ce = (BRAM_PORTA_en==1'b1) 
				&& (BRAM_PORTA_addr[15:10]==1'b0) 
				&& (BRAM_PORTA_addr[1:0]==2'b0);

assign	cpu_we = cpu_ce && (BRAM_PORTA_we==4'hf);
assign 	cpu_rd_en = cpu_ce && (~cpu_we);
assign 	cpu_addr = BRAM_PORTA_addr[9:2];
assign	cpu_wdata = BRAM_PORTA_din;

assign	BRAM_PORTA_dout = testprj_rd_en_d1? testprj_rd_dat : cpu_rd_en_d1? cpu_rdata : 32'b0;

always @(posedge rst or posedge clk) begin
	if(rst) begin
		cpu_rd_en_d1 <= 1'b0;
		cpu_addr_d1 <= 1'b0;
		testprj_rd_en_d1 <= 1'b0;
	end
	else begin
		cpu_rd_en_d1 <= cpu_rd_en;
		cpu_addr_d1 <= cpu_addr;
		testprj_rd_en_d1 <= testprj_rd_en;
	end
end

always @(posedge rst or posedge clk) begin
	if(rst) begin
		cpu_rdata <= 'h0;
	end
	else if(cpu_rd_en) begin
		case(cpu_addr[7:0])
			8'h0  :    cpu_rdata <= VERSION; 
			//Add signals of user test project 
			8'h20 :    cpu_rdata <= {24'b0, i_data_real             };  //output  reg     [8-1:0] 
			8'h21 :    cpu_rdata <= {24'b0, i_data_imag             };  //output  reg     [8-1:0] 
			8'h22 :    cpu_rdata <= {14'b0, filtRslt_real           };  //input           [18-1:0]
			8'h23 :    cpu_rdata <= {14'b0, filtRslt_imag           };  //input           [18-1:0]
			
			//FI platform contral signal:
			8'h1  :	   cpu_rdata <=  execution_cyc_length			 ;	//output	[31:0]
			8'h2  :	   cpu_rdata <=  inject_cycle					 ;	//output	[31:0]
			8'h3  :    cpu_rdata <= {24'b0, ia_upper    			};	//output	[7 :0]
			8'h4  :    cpu_rdata <=  ia_lower						 ;	//output	[31:0]
			                                                           
			8'h5  :    cpu_rdata <= {31'b0, icap_grant  			};	//output	[0 :0]
			8'h6  :    cpu_rdata <= {31'b0, icap_sel             	}; 	//output	[0 :0]
			8'h7  :    cpu_rdata <= {31'b0, inject_enable    		};	//output	[0 :0]
			8'h8 :     cpu_rdata <= {31'b0, inject_strobe			};	//output	[0 :0]
			8'h9 :     cpu_rdata <= {31'b0, mask_exp             	};	//output	[0 :0]
			8'ha :     cpu_rdata <= {31'b0, mask_inj            	};	//output	[0 :0]
			8'hb :     cpu_rdata <= {31'b0, halt_from_processor	};	//output	[0 :0]
			8'hc :     cpu_rdata <= {31'b0, gsr					};	//output	[0 :0]
			8'hd :     cpu_rdata <= {31'b0, reset_rtl				};	//output	[0 :0]
			8'he :     cpu_rdata <= {31'b0, sem_clk_en				};	//output	[0 :0]
			
			8'hf :     cpu_rdata <= {31'b0, expired_cycle			};	//input		[0 :0]
			8'h10 :    cpu_rdata <= {31'b0, dut_clock_stopped		};	//input		[0 :0]
			8'h11 :    cpu_rdata <= {31'b0, error					};	//input		[0 :0]
			8'h12 :    cpu_rdata <= current_cycle			         ;	//input		[0 :0]
			8'h13 :    cpu_rdata <= {31'b0, inject_cycle_reached	};	//input		[0 :0]
			8'h14 :    cpu_rdata <= {30'b0, status_injection_latch, status_injection};	//input		[1:0]
            
            8'h15 :    cpu_rdata <=  32'b0                           ;	//input		[0 :0]  //写入串口指令 包含空格和回车 ，间隔1ms写一次
            8'h16 :    cpu_rdata <= {24'b0, fifo_cnt                };	//input		[0 :0]  //当fifo_cnt 不等于0且不变化时可以读取8'h17寄存器，间隔1ms读一次
            8'h17 :    cpu_rdata <= {24'b0, fifo_dout               };	//input		[0 :0]  //读取的数据，间隔1ms读一次
            8'h18 :    cpu_rdata <= {31'b0, status_initialization   };
            8'h19 :    cpu_rdata <= {31'b0, status_observation      };
            8'h1a :    cpu_rdata <= {31'b0, command_busy            };
            8'h1b :    cpu_rdata <= {30'b0, status_heartbeat, continue_run };
            8'h1c :    cpu_rdata <= {28'b0, status_uncorrectable, status_essential, status_classification, status_correction};
         

            
			default : cpu_rdata <= 'h0;
		endcase
	end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        i_data_real <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'h20)begin
        i_data_real <= cpu_wdata[7:0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        i_data_imag <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'h21)begin
        i_data_imag <= cpu_wdata[7:0];
    end
end

//FI platform contral signal:
always @(posedge clk or posedge rst)begin
    if(rst)
        execution_cyc_length <= 32'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'h1)begin
        execution_cyc_length <= cpu_wdata[31:0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        inject_cycle <= 32'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'h2)begin
        inject_cycle <= cpu_wdata[31:0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        ia_upper <= 8'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'h3)begin
        ia_upper <= cpu_wdata[7:0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        ia_lower <= 32'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'h4)begin
        ia_lower <= cpu_wdata[31:0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        icap_grant <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'h5)begin
        icap_grant <= cpu_wdata[0];
    end
end		

always @(posedge clk or posedge rst)begin
    if(rst)
        icap_sel <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'h6)begin
        icap_sel <= cpu_wdata[0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        inject_enable <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'h7)begin
        inject_enable <= cpu_wdata[0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        inject_strobe <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'h8)begin
        inject_strobe <= cpu_wdata[0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        status_injection_latch <= 1'b0;
    else if(cpu_we && cpu_addr[7:0]==8'h8 && cpu_wdata[0]==1'b1)
        status_injection_latch <= 1'b0;
    else if(status_injection)
        status_injection_latch <= 1'b1;
end

always @(posedge clk or posedge rst)begin
    if(rst)
        mask_exp <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'h9)begin
        mask_exp <= cpu_wdata[0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        mask_inj <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'ha)begin
        mask_inj <= cpu_wdata[0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        halt_from_processor <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'hb)begin
        halt_from_processor <= cpu_wdata[0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        gsr <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'hc)begin
        gsr <= cpu_wdata[0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        reset_rtl <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'hd)begin
        reset_rtl <= cpu_wdata[0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        sem_clk_en <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'he)begin
        sem_clk_en <= cpu_wdata[0];
    end
end

always @(posedge clk or posedge rst)begin
    if(rst)
        continue_run <= 1'b0;
    else if(cpu_we &&cpu_addr[7:0]==8'h1b)begin
        continue_run <= cpu_wdata[0];
    end
end


always @(posedge clk or posedge rst)begin
    if(rst)begin
        fifo_din        <= 8'b0;
        fifo_din_vld    <= 1'b0;
    end
    else if(cpu_we &&cpu_addr[7:0]==8'h15)begin
        fifo_din <= cpu_wdata[70];
        fifo_din_vld    <= 1'b1;
    end
    else begin
        fifo_din_vld    <= 1'b0;
    end
end


assign fifo_rd_en   = cpu_rd_en & cpu_addr[7:0]==8'h17 ;





endmodule
