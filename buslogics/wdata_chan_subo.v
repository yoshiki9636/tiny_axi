/*
 * My RISC-V RV32I CPU
 *  write data channel subordinate
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2024 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module wdata_chan_subo (
	input clk,
	input rst_n,

	// bus signals
	input wvalid,
	output  wready,
	input [31:0] wdata,
	input wlast,
	// signals other side
	input next_srq,
	input sqfull_1,
	output [127:0] wdat_s_data,
	output reg wdat_s_valid,
	output finish_swd

	);

`define WDAT_SIDLE 3'b000
`define WDAT_SBINP 3'b001
`define WDAT_SLST1 3'b010
`define WDAT_SBUSY 3'b011
`define WDAT_SDEFO 3'b111

// write data channel manager state machine
reg [2:0] wdat_s_current;

function [2:0] wdat_s_decode;
input [2:0] wdat_s_current;
input next_srq;
input wvalid;
input wlast;
input sqfull_1;
begin
    case(wdat_s_current)
		`WDAT_SIDLE: begin
    		case(next_srq)
				1'b1: wdat_s_decode = `WDAT_SBINP;
				1'b0: wdat_s_decode = `WDAT_SIDLE;
				default: wdat_s_decode = `WDAT_SDEFO;
    		endcase
		end
		`WDAT_SBINP: begin
    		casex({wvalid, wlast, sqfull_1, next_srq})
				4'b0xxx: wdat_s_decode = `WDAT_SBINP;
				4'b10xx: wdat_s_decode = `WDAT_SBINP;
				4'b1100: wdat_s_decode = `WDAT_SIDLE;
				4'b1101: wdat_s_decode = `WDAT_SBINP;
				4'b1110: wdat_s_decode = `WDAT_SBUSY;
				4'b1111: wdat_s_decode = `WDAT_SLST1;
				default: wdat_s_decode = `WDAT_SDEFO;
    		endcase
		end
		`WDAT_SLST1: begin
    		casex({wvalid, wlast,sqfull_1,next_srq})
				4'b0xxx: wdat_s_decode = `WDAT_SLST1;
				4'b10xx: wdat_s_decode = `WDAT_SLST1;
				4'b111x: wdat_s_decode = `WDAT_SBUSY;
				4'b1101: wdat_s_decode = `WDAT_SBINP;
				4'b1100: wdat_s_decode = `WDAT_SIDLE;
				default: wdat_s_decode = `WDAT_SDEFO;
    		endcase
		end
		`WDAT_SBUSY: begin
    		casex({sqfull_1,next_srq})
				2'b1x: wdat_s_decode = `WDAT_SBUSY;
				2'b01: wdat_s_decode = `WDAT_SBINP;
				2'b00: wdat_s_decode = `WDAT_SIDLE;
				default: wdat_s_decode = `WDAT_SDEFO;
    		endcase
		end
		`WDAT_SDEFO: wdat_s_decode = `WDAT_SDEFO;
		default:     wdat_s_decode = `WDAT_SDEFO;
   	endcase
end
endfunction

wire [2:0] wdat_s_next = wdat_s_decode( wdat_s_current, next_srq, wvalid, wlast, sqfull_1 );

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        wdat_s_current <= `WDAT_SIDLE;
    else
        wdat_s_current <= wdat_s_next;
end

assign wready = (wdat_s_current == `WDAT_SBINP)|(wdat_s_current == `WDAT_SLST1);

// burst counter just spport 4
reg [1:0] burst_cntr;

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        burst_cntr <= 2'd0;
    else if (wlast & wvalid)
        burst_cntr <= 2'd0;
    else if (wready & wvalid)
        burst_cntr <= burst_cntr + 2'd1;
end

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        wdat_s_valid <= 1'b0;
    else
        wdat_s_valid <= wlast;
end

assign finish_swd = wdat_s_valid;

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

assign wdat_s_data = { wdata_ofs3, wdata_ofs2, wdata_ofs1, wdata_ofs0 };

endmodule
