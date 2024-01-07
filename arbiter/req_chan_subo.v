/*
 * My RISC-V RV32I CPU
 *  request channel manager
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2024 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module req_chan_subo (
	input clk,
	input rst_n,
	// bus signals
	input a_valid,
	output  a_ready,
	input [3:0] a_id,
	input [31:0] a_addr,
	input [5:0] a_atop, // currently not used
	// signals other side
	output reqc_s_valid,
	output [3:0] reqc_s_id,
	output [31:0] reqc_s_addr

	);

`define REQC_SIDLE 2'b00
`define REQC_SBUSY 2'b01
`define REQC_SDEFO 2'b11


// no address decoder : just 1 subordinate exists
wire qfull_1;
assign a_ready = ~qfull_1;

wire ram_wen = a_valid & a_ready;
wire [35:0] ram_wdata = { a_id, a_addr };
wire [35:0] ram_rdata;

reqc_s_1r1w reqc_s_1r1w (
	.clk(clk),
	.ram_radr(ram_radr),
	.ram_rdata(ram_rdata),
	.ram_wadr(ram_wadr),
	.ram_wdata(ram_wdata),
	.ram_wen(ram_wen)
	);

reg [1:0] ram_radr;
reg [1:0] ram_wadr;
reg [2:0] ram_udcntr;

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        ram_wadr <= 2'd0;
    else if (ram_wen)
        ram_wadr <= ram_wadr + 2'd1;
end

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        ram_radr <= 2'd0;
    else if (ram_rnext)
        ram_radr <= ram_radr + 2'd1;
end

always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        ram_udcntr <= 3'd0;
    else if (ram_wen & ram_rnext)
        ram_udcntr <= ram_udcntr;
    else if (ram_rnext)
        ram_udcntr <= ram_udcntr - 3'd1;
    else if (ram_wen)
        ram_udcntr <= ram_udcntr + 3'd1;
end

assign qfull_1 = (ram_udcntr > 3'd3);
assign reqc_s_valid = (ram_udcntr > 3'd0);
assign reqc_s_id = ram_rdata[35:32];
assign reqc_s_addr = ram_rdata[31:0];

endmodule
