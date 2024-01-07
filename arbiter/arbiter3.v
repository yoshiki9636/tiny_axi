/*
 * My RISC-V RV32I CPU
 *   arbiter for tiny axi bus
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2024 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module arbitor3 (
	input clk,
	input rst_n,

	input req0,
	input req1,
	input req2,

	output gnt0,
	output gnt1,
	output gnt2,

	output [2:0] sel,
	input finish

	);

`define ARB3_IDL012 3'b000
`define ARB3_SEL012 3'b001
`define ARB3_IDL120 3'b010
`define ARB3_SEL120 3'b011
`define ARB3_IDL201 3'b100
`define ARB3_SEL201 3'b101
`define ARB3_SELDEF 3'b111

// round robin state machine
reg [2:0] arbit3_current;

function [10:0] arbit3_decode;
input [2:0] arbit3_current;
input req0;
input req1;
input req2;
input finish;
begin
    case(arbit3_current)
		`ARB3_IDL012: begin
    		casex({req0,req1,req2})
				3'b1xx: arbit3_decode = `ARB3_SEL012;
				3'b01x: arbit3_decode = `ARB3_SEL120;
				3'b001: arbit3_decode = `ARB3_SEL201;
				3'b000: arbit3_decode = `ARB3_IDL012;
				default: arbit3_decode = `ARB3_SELDEF;
    		endcase
		`ARB3_SEL012: begin
    		casex({finish,req1,req2,req0})
				4'b0xxx: arbit3_decode = `ARB3_SEL012;
				4'b11xx: arbit3_decode = `ARB3_SEL120;
				4'b101x: arbit3_decode = `ARB3_SEL201;
				4'b1001: arbit3_decode = `ARB3_SEL012;
				4'b1000: arbit3_decode = `ARB3_IDL120;
				default: arbit3_decode = `ARB3_SELDEF;
    		endcase
		`ARB3_IDL120: begin
    		casex({req1,req2,req0})
				3'b1xx: arbit3_decode = `ARB3_SEL120;
				3'b01x: arbit3_decode = `ARB3_SEL201;
				3'b001: arbit3_decode = `ARB3_SEL012;
				3'b000: arbit3_decode = `ARB3_IDL120;
				default: arbit3_decode = `ARB3_SELDEF;
    		endcase
		`ARB3_SEL120: begin
    		casex({finish,req2,req0,req1})
				4'b0xxx: arbit3_decode = `ARB3_SEL120;
				4'b11xx: arbit3_decode = `ARB3_SEL201;
				4'b101x: arbit3_decode = `ARB3_SEL012;
				4'b1001: arbit3_decode = `ARB3_SEL120;
				4'b1000: arbit3_decode = `ARB3_IDL201;
				default: arbit3_decode = `ARB3_SELDEF;
    		endcase
		`ARB3_IDL201: begin
    		casex({req2,req0,req1})
				3'b1xx: arbit3_decode = `ARB3_SEL201;
				3'b01x: arbit3_decode = `ARB3_SEL012;
				3'b001: arbit3_decode = `ARB3_SEL120;
				3'b000: arbit3_decode = `ARB3_IDL201;
				default: arbit3_decode = `ARB3_SELDEF;
    		endcase
		`ARB3_SEL201: begin
    		casex({finish,req0,req1,req2})
				4'b0xxx: arbit3_decode = `ARB3_SEL201;
				4'b11xx: arbit3_decode = `ARB3_SEL012;
				4'b101x: arbit3_decode = `ARB3_SEL120;
				4'b1001: arbit3_decode = `ARB3_SEL201;
				4'b1000: arbit3_decode = `ARB3_IDL012;
				default: arbit3_decode = `ARB3_SELDEF;
    		endcase
		`ARB3_SELDEF: arbit3_decode = `ARB3_SELDEF;
		default:      arbit3_decode = `ARB3_SELDEF;
   	endcase
end
endfunction

wire [2:0] arbit3_next = arbit3_decode( arbit3_current, req0, req1, req2 );

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        arbit3_current <= `ARB3_IDL012;
    else
        arbit3_current <= arbit3_next;
end


wire sel0_pre = (arbit3_next = `ARB3_SEL012);
wire sel1_pre = (arbit3_next = `ARB3_SEL120);
wire sel2_pre = (arbit3_next = `ARB3_SEL201);

reg sel0_post;
reg sel1_post;
reg sel2_post;
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        sel0_post <= 1'b0;
        sel1_post <= 1'b0;
        sel2_post <= 1'b0;
	end
    else begin
        sel0_post <= sel0_pre;
        sel1_post <= sel0_pre;
        sel2_post <= sel0_pre;
    else begin
end

assign gnt0 = sel0_pre & ~sel0_post;
assign gnt1 = sel1_pre & ~sel1_post;
assign gnt2 = sel2_pre & ~sel2_post;

assign sel = { sel2_post, sel1_post, sel0_post };

endmodule
