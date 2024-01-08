/*
 * My RISC-V RV32I CPU
 *  response channel manager
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2024 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module wresp_chan_mngr (
	input clk,
	input rst_n,

	// bus signals
	input bvalid,
	output  bready,
	input [31:0] bid,
	input bcomp,
	// signals other side
	input finish_wd,
	input [31:0] finish_id,
	output finish_wresp

	);

`define WRSP_MIDLE 2'b00
`define WRSP_MBINP 2'b01
`define WRSP_MDEFO 2'b11

// write data channel manager state machine
reg [1:0] resp_m_current;

function [1:0] resp_m_decode;
input [1:0] resp_m_current;
input finish_wd;
input wlast;
input sqfull_1;
begin
    case(resp_m_current)
		`WRSP_MIDLE: begin
    		case(next_srq)
				1'b1: resp_m_decode = `WRSP_MBINP;
				1'b0: resp_m_decode = `WRSP_MIDLE;
				default: resp_m_decode = `WRSP_MDEFO;
    		endcase
		`WRSP_MBINP: begin
    		casex({wlast, sqfull_1. next_srq})
				3'b0xx: resp_m_decode = `WRSP_MBINP;
				3'b100: resp_m_decode = `WRSP_MIDLE;
				3'b101: resp_m_decode = `WRSP_MBINP;
				3'b110: resp_m_decode = `WRSP_MBUSY;
				3'b111: resp_m_decode = `WRSP_MLST1;
				default: resp_m_decode = `WRSP_MDEFO;
    		endcase
		`WRSP_MLST1: begin
    		casex({wlast,sqfull_1,next_srq})
				3'b0xx: resp_m_decode = `WRSP_MLST1;
				3'b11x: resp_m_decode = `WRSP_MBUSY;
				3'b101: resp_m_decode = `WRSP_MBINP;
				3'b100: resp_m_decode = `WRSP_MIDLE;
				default: resp_m_decode = `WRSP_MDEFO;
    		endcase
		`WRSP_MBUSY: begin
    		casex({sqfull_1,next_srq})
				2'b1x: resp_m_decode = `WRSP_MBUSY;
				2'b01: resp_m_decode = `WRSP_MBINP;
				2'b00: resp_m_decode = `WRSP_MIDLE;
				default: resp_m_decode = `WRSP_MDEFO;
    		endcase
		`WRSP_MDEFO: resp_m_decode = `WRSP_MDEFO;
		default:     resp_m_decode = `WRSP_MDEFO;
   	endcase
end
endfunction

wire [1:0] resp_m_next = resp_m_decode( resp_m_current, next_srq, wlast, sqfull_1 );

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        resp_m_current <= `WRSP_MIDLE;
    else
        resp_m_current <= resp_m_next;
end

	output  wready,
assign wready = (resp_m_current == `WRSP_MBINP)|(resp_m_current == `WRSP_MLST1);

// burst counter just spport 4
reg [1:0] burst_cntr;

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        burst_cntr <= 2'd0;
    else if (next_srq)
        burst_cntr <= 2'd0;
    else if (wlast)
        burst_cntr <= 2'd0;
    else if (wready & wvalid)
        burst_cntr <= burst_cntr + 2'd1;
end

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        resp_m_valid <= 1'b0;
    else
        resp_m_valid <= wlast;
end

assign finish_swd = resp_m_valid;

// data buffer
reg [31:0] wdata_ofs0;
reg [31:0] wdata_ofs1;
reg [31:0] wdata_ofs2;
reg [31:0] wdata_ofs3;

// write enables
wire wdata_ofs0_wen = wready & wvalid & (burst_cntr == 2'd0);
wire wdata_ofs1_wen = wready & wvalid & (burst_cntr == 2'd1);
wire wdata_ofs2_wen = wready & wvalid & (burst_cntr == 2'd2);
wire wdata_ofs3_wen = wready & wvalid & (burst_cntr == 2'd3);

// data ofs 0
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
       wdata_ofs0  <= 32'd0;
    else if (wdata_ofs0_wen)
       wdata_ofs0  <= wdata;
end

// data ofs 1
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
       wdata_ofs1  <= 32'd0;
    else if (wdata_ofs0_wen & wlast)
       wdata_ofs1  <= 32'd0;
    else if (wdata_ofs1_wen)
       wdata_ofs1  <= wdata;
end

// data ofs 2
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
       wdata_ofs2  <= 32'd0;
    else if ((wdata_ofs0_wen | wdata_ofs1_wen) & wlast)
       wdata_ofs2  <= 32'd0;
    else if (wdata_ofs2_wen)
       wdata_ofs2  <= wdata;
end

// data ofs 3
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
       wdata_ofs3  <= 32'd0;
    else if ((wdata_ofs0_wen | wdata_ofs1_wen | wdata_ofs2_wen) & wlast)
       wdata_ofs3  <= 32'd0;
    else if (wdata_ofs3_wen)
       wdata_ofs3  <= wdata;
end

assign resp_m_data = { wdata_ofs3, wdata_ofs2, wdata_ofs1, wdata_ofs0 };

endmodule
