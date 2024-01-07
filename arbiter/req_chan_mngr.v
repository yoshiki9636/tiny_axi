/*
 * My RISC-V RV32I CPU
 *  request channel manager
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2024 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module req_chan_mngr
    #(parameter REQC_M_ID = 2'b00)
    (
	input clk,
	input rst_n,
	//bus controls
	output req_rq,
	input gnt_rq,
	// bus signals
	output a_valid,
	input  a_ready,
	output [3:0] a_id,
	output reg [31:0] a_addr,
	output [5:0] a_atop,
	// signals other side
	input start_rq,
	output next_rq,
	output [3:0] next_id,
	input [31:0] in_addr

	);

`define REQC_MIDLE 2'b00
`define REQC_MAREQ 2'b01
`define REQC_MBOUT 2'b10
`define REQC_MDEFO 2'b11

// fixed signal : for supporting in the future

assign a_atop = 6'b000000; // non-atomic

// Request channel manager state machine
reg [1:0] reqc_m_current;

function [10:0] reqc_m_decode;
input [1:0] reqc_m_current;
input start_rq;
input gnt_rq;
input a_ready;
begin
    case(reqc_m_current)
		`REQC_MIDLE: begin
    		case(start_rq)
				1'b1: reqc_m_decode = `REQC_MAREQ;
				1'b0: reqc_m_decode = `REQC_MIDLE;
				default: reqc_m_decode = `REQC_MDEFO;
    		endcase
		`REQC_MAREQ: begin
    		case(gnt_rq)
				1'b1: reqc_m_decode = `REQC_MBOUT;
				1'b0: reqc_m_decode = `REQC_MAREQ;
				default: reqc_m_decode = `REQC_MDEFO;
    		endcase
		`REQC_MBOUT: begin
    		casex({a_ready,start_rq})
				2'b0x: reqc_m_decode = `REQC_MBOUT;
				2'b10: reqc_m_decode = `REQC_MIDLE;
				2'b11: reqc_m_decode = `REQC_MAREQ;
				default: reqc_m_decode = `REQC_MDEFO;
    		endcase
		`REQC_MDEFO: reqc_m_decode = `REQC_MDEFO;
		default:      reqc_m_decode = `REQC_MDEFO;
   	endcase
end
endfunction

wire [1:0] reqc_m_next = reqc_m_decode( reqc_m_current, start_rq, gnt_rq, a_ready );

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        reqc_m_current <= `REQC_MIDLE;
    else
        reqc_m_current <= reqc_m_next;
end

assign req_rq = (reqc_m_current == `REQC_MAREQ);
assign a_valid = (reqc_m_current == `REQC_MBOUT);
assign next_rq = a_valid & a_ready;

// id maker
reg [1:0] id_cntr;

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        id_cntr <= 2'd0;
    else if (start_rq)
        id_cntr <= id_cntr + 2'd1;
end

assign a_id = { REQC_M_ID, id_cntr };

// address keeper
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
       a_addr  <= 32'd0;
    else if (start_rq)
       a_addr  <= in_addr;
end

endmodule
