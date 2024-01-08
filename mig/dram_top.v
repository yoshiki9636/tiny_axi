/*
 * My RISC-V RV32I CPU
 *   dram interface top
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2024 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module dram_top (
	// mig ingerface
	input mclk,
	input mrst_n,
	// address/command
	output [27:0] app_addr,
	output [2:0] app_cmd,
	output app_en,
	input app_rdy,
	// write data
	output [127:0] app_wdf_data,
	output [15:0] app_wdf_mask,
	output app_wdf_wren,
	output app_wdf_end,
	input app_wdf_rdy,
	// read data
	input [127:0] app_rd_data,
	input app_rd_data_end,
	input app_rd_data_valid,

	// bus clock
	input clk,
	input rst_n,
	// write request
    input awvalid,
    output  awready,
    input [3:0] awid,
    input [31:0] awaddr,
    input [5:0] awatop,
	// write data
    input wvalid,
    output  wready,
    input [31:0] wdata,
    input wlast,
	// write response
    output bvalid,
    input  bready,
    output reg [3:0] bid,
    output bcomp,
	// read request
    input awvalid,
    output  awready,
    input [3:0] awid,
    input [31:0] awaddr,
	// read data
    output rvalid,
    input  rready,
    output reg [3:0] rid,
    output [31:0] rdata,
    output rlast

	);

wire wqfull_1; // input
wire wreqc_s_valid; // output
wire [31:0] wreqc_s_addr; // output
wire sqfull_1; // input
wire [127:0] wdat_s_data; // output
wire wdat_s_valid; // output

wire rqfull_1; // input
wire rreqc_s_valid; // output
wire [3:0] rreqc_s_id; // output
wire [31:0] rreqc_s_addr; // output

wire rdata_s_valid; // input
wire [3:0] rdata_s_id; // input
wire [127:0] rdata_s_data; // input
wire finish_rdata_s; // output

// write bus interface
write_channels_subo write_channels_subo (
	.clk(clk),
	.rst_n(rst_n),
	.awvalid(awvalid),
	.awready(awready),
	.awid(awid),
	.awaddr(awaddr),
	.awatop(awatop),
	.wvalid(wvalid),
	.wready(wready),
	.wdata(wdata),
	.wlast(wlast),
	.bvalid(bvalid),
	.bready(bready),
	.bid(bid),
	.bcomp(bcomp),
	.wqfull_1(wqfull_1),
	.wreqc_s_valid(wreqc_s_valid),
	.wreqc_s_addr(wreqc_s_addr),
	.sqfull_1(sqfull_1),
	.wdat_s_data(wdat_s_data),
	.wdat_s_valid(wdat_s_valid)
	);

// read bus interface
read_channels_subo read_channels_subo (
	.clk(clk),
	.rst_n(rst_n),
	.arvalid(arvalid),
	.arready(arready),
	.arid(arid),
	.araddr(araddr),
	.rvalid(rvalid),
	.rready(rready),
	.rid(rid),
	.rdata(rdata),
	.rlast(rlast),
	.rqfull_1(rqfull_1),
	.rreqc_s_valid(rreqc_s_valid),
	.rreqc_s_id(rreqc_s_id),
	.rreqc_s_addr(rreqc_s_addr),
	.rdata_s_valid(rdata_s_valid),
	.rdata_s_id(rdata_s_id),
	.rdata_s_data(rdata_s_data),
	.finish_rdata_s(finish_rdata_s)
	);


endmodule
