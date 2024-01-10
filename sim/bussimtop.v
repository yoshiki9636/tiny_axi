/*
 * My RISC-V RV32I CPU
 *   Verilog Simulation Top Module
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2021 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module bussimtop;

reg clk;
reg rst_n;
reg mclk;
reg mrst_n;

initial clk = 0;
initial mclk = 1;

always #5 clk <= ~clk;
always #5 mclk <= ~mclk;

// MIG interface
wire [27:0] app_addr; // output
wire [2:0] app_cmd; // output
wire app_en; // output
wire app_rdy = 1'b1; // input

wire [127:0] app_wdf_data; // output
wire [15:0] app_wdf_mask; // output
wire app_wdf_wren; // output
wire app_wdf_end; // output
wire app_wdf_rdy = 1'b1; // input

reg [127:0] app_rd_data; // input
reg app_rd_data_end; // input
reg app_rd_data_valid; // input

// axi write bus manager
reg wstart_rq; // input
reg [31:0] win_addr; // input
reg [127:0] in_wdata; // input
wire finish_wresp; // output

// axi read bus manager
reg rstart_rq; // input
reg [31:0] rin_addr; // input
//wire rnext_rq; // output
wire [3:0] rnext_id; // output
//reg [3:0] next_rid; // input
reg rqfull_1;
wire [127:0] rdat_m_data; // output
wire rdat_m_valid; // output

initial begin
	app_rd_data = 128'd0;
	app_rd_data_end = 1'b0;
	app_rd_data_valid = 1'b0;

	wstart_rq = 1'b0;
	win_addr = 32'd0;
	in_wdata = 128'd0;

	rstart_rq = 1'b0;
	rqfull_1 = 1'b0;
	rin_addr = 32'd0;

	rst_n = 1'b1;
	mrst_n = 1'b1;
#11
	rst_n = 1'b0;
	mrst_n = 1'b0;
#20
	rst_n = 1'b1;
	mrst_n = 1'b1;
#20

	rstart_rq = 1'b1;
	rin_addr = 32'hdeaddead;

#10
	rin_addr = 32'hbeefbeef;
#10
	rstart_rq = 1'b0;

#10
	wstart_rq = 1'b1;
	win_addr = 32'hdeadbeef;
	in_wdata = 128'h4444_4444_3333_3333_2222_2222_1111_1111;
#10
	win_addr = 32'hbeefdead;
	in_wdata = 128'h8888_8888_7777_7777_6666_6666_5555_5555;
#10
	wstart_rq = 1'b0;
	win_addr = 32'h00000000;
	in_wdata = 128'd0;

#300
	app_rd_data = 128'h9999_9999_aaaa_aaaa_bbbb_bbbb_cccc_cccc;
	app_rd_data_end = 1'b1;
	app_rd_data_valid = 1'b1;
#10
	app_rd_data = 128'd0;
	app_rd_data_end = 1'b0;
	app_rd_data_valid = 1'b0;
#100
	app_rd_data = 128'hdddd_dddd_eeee_eeee_ffff_ffff_0101_0101;
	app_rd_data_end = 1'b1;
	app_rd_data_valid = 1'b1;
#10
	app_rd_data = 128'd0;
	app_rd_data_end = 1'b0;
	app_rd_data_valid = 1'b0;

#5000
	$stop;
end






// arbiter signals
wire req_dc_wt;
wire gnt_dc_wt;
wire gnt1_wt;
wire gnt2_wt;
wire [2:0] sel_wt;
wire req_dc_rd;
wire gnt_dc_rd;
wire gnt1_rd;
wire gnt2_rd;
wire [2:0] sel_rd;

// axi bus signals
wire awvalid;
wire awready;
wire [3:0] awid;
wire [31:0] awaddr;
wire [5:0] awatop;
wire wvalid;
wire wready;
wire [31:0] wdata;
wire wlast;
wire bvalid;
wire bready;
wire [3:0] bid;
wire bcomp;
wire arvalid;
wire arready;
wire [3:0] arid;
wire [31:0] araddr;
wire rvalid;
wire rready;
wire [3:0] rid;
wire [31:0] rdata;
wire rlast;


dram_top dram_top (
	.mclk(mclk),
	.mrst_n(mrst_n),
	.app_addr(app_addr),
	.app_cmd(app_cmd),
	.app_en(app_en),
	.app_rdy(app_rdy),
	.app_wdf_data(app_wdf_data),
	.app_wdf_mask(app_wdf_mask),
	.app_wdf_wren(app_wdf_wren),
	.app_wdf_end(app_wdf_end),
	.app_wdf_rdy(app_wdf_rdy),
	.app_rd_data(app_rd_data),
	.app_rd_data_end(app_rd_data_end),
	.app_rd_data_valid(app_rd_data_valid),
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
	.arvalid(arvalid),
	.arready(arready),
	.arid(arid),
	.araddr(araddr),
	.rvalid(rvalid),
	.rready(rready),
	.rid(rid),
	.rdata(rdata),
	.rlast(rlast)
	);

write_channels_mngr write_channels_mngr (
	.clk(clk),
	.rst_n(rst_n),
	.req_rq(req_dc_wt),
	.gnt_rq(gnt_dc_wt),
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
	.wstart_rq(wstart_rq),
	.win_addr(win_addr),
	.in_wdata(in_wdata),
	.finish_wresp(finish_wresp)
	);

read_channels_mngr read_channels_mngr (
	.clk(clk),
	.rst_n(rst_n),
	.req_rq(req_dc_rd),
	.gnt_rq(gnt_dc_rd),
	.arvalid(arvalid),
	.arready(arready),
	.arid(arid),
	.araddr(araddr),
	.rvalid(rvalid),
	.rready(rready),
	.rid(rid),
	.rdata(rdata),
	.rlast(rlast),
	.rstart_rq(rstart_rq),
	.rin_addr(rin_addr),
	//.rnext_rq(rnext_rq),
	.rnext_id(rnext_id),
	.next_rid(rnext_id), // kari
	.rqfull_1(rqfull_1),
	.rdat_m_data(rdat_m_data),
	.rdat_m_valid(rdat_m_valid),
	.finish_mrd(finish_mrd)
	);

arbitor3 write_arb (
	.clk(clk),
	.rst_n(rst_n),
	.req0(req_dc_wt),
	.req1(1'b0),
	.req2(1'b0),
	.gnt0(gnt_dc_wt),
	.gnt1(gnt1_wt),
	.gnt2(gnt2_wt),
	.sel(sel_wt),
	.finish(finish_wresp)
	);

arbitor3 read_arb (
	.clk(clk),
	.rst_n(rst_n),
	.req0(req_dc_rd),
	.req1(1'b0),
	.req2(1'b0),
	.gnt0(gnt_dc_rd),
	.gnt1(gnt1_rd),
	.gnt2(gnt2_rd),
	.sel(sel_rd),
	.finish(finish_mrd)
	);


endmodule
