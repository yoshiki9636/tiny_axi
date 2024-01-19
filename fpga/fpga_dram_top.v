/*
 * My RISC-V RV32I CPU
 *   FPGA Top Module for Tang Premier
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2021 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

//`define TANG_PRIMER
`define ARTY_A7

module fpga_dram_top(
	input clkin,
	input rst_n,
	input rx,
	output tx,
	output [2:0] rgb_led,

// ddr signal
	inout [15:0] ddr3_dq,
	inout [1:0] ddr3_dqs_n,
	inout [1:0] ddr3_dqs_p,
	output [13:0] ddr3_addr,
	output [2:0] ddr3_ba,
	output ddr3_ras_n,
	output ddr3_cas_n,
	output ddr3_we_n,
	output ddr3_reset_n,
	output [0:0] ddr3_ck_p,
	output [0:0] ddr3_ck_n,
	output [0:0] ddr3_cke,
	output [0:0] ddr3_cs_n,
	output [1:0] ddr3_dm,
	output [0:0] ddr3_odt

	);

`ifdef TANG_PRIMER
parameter DWIDTH = 12;
//parameter DWIDTH = 14;
`endif
`ifdef ARTY_A7
//parameter DWIDTH = 12;
parameter DWIDTH = 14;
`endif


//wire [DWIDTH+1:2] d_ram_radr;
//wire [DWIDTH+1:2] d_ram_wadr;
//wire [31:0] d_ram_rdata;
//wire [31:0] d_ram_wdata;
//wire d_ram_wen;
wire d_read_sel;

wire [13:2] i_ram_radr;
wire [13:2] i_ram_wadr;
wire [31:0] i_ram_rdata = 32'd0;
wire [31:0] i_ram_wdata;
wire i_ram_wen;
wire i_read_sel;

wire [31:2] start_adr;
wire cpu_start;
wire quit_cmd;
wire [31:0] pc_data = 32'd0;

wire clk;
wire stdby = 1'b0 ;


//wire mclk;
//wire mrst_n;


// axi write bus manager
wire wstart_rq; // input
wire [31:0] win_addr; // input
wire [127:0] in_wdata; // input
wire [15:0] in_mask; // input
wire finish_wresp; // output

// axi read bus manager
wire rstart_rq; // input
wire [31:0] rin_addr; // input
//wire rnext_rq; // output
wire [3:0] rnext_id; // output
//reg [3:0] next_rid; // input
wire rqfull_1 = 1'b0;
wire [127:0] rdat_m_data; // output
//wire [15:0] rdat_m_mask; // output
wire rdat_m_valid; // output


// MIG interface
wire [27:0] app_addr; // input
wire [2:0] app_cmd; // input
wire app_en; // input
wire app_rdy; // output
wire [127:0] app_wdf_data; // input
wire [15:0] app_wdf_mask; // input
wire app_wdf_wren; // input
wire app_wdf_end; // input
wire app_wdf_rdy; // output
wire [127:0] app_rd_data; // output
wire app_rd_data_end; // output
wire app_rd_data_valid; // output

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
wire [3:0] wstrb;
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

wire clk_200mhz;
wire clk_166mhz;

`ifdef ARTY_A7
wire locked;

 // Instantiation of the clocking network
 //--------------------------------------
  clk_wiz_0 clknetwork
   (
    // Clock out ports
    .clk_out1           (clk_200mhz),
    .clk_out2           (clk_166mhz),
    .clk_out3           (clk),

    // Status and control signals
    .reset              (~rst_n),
    .locked             (locked),
   // Clock in ports
    .clk_in1            (clkin)
	);
	

`endif

`ifdef TANG_PRIMER
wire clklock;
pll pll (
	.refclk(clkin),
	.reset(~rst_n),
	//.stdby(stdby),
	.extlock(clklock),
	.clk0_out(clk)
	);
`endif

//assign mclk = clk;
//assign mrst_n = rst_n;


wire sys_clk_i = clk_166mhz; // input
wire clk_ref_i = clk_200mhz; // input
//wire sys_clk_i = clk_200mhz; // input
//wire clk_ref_i = clk_166mhz; // input

// MIG interface
wire app_sr_req = 1'b0; // input
wire app_ref_req = 1'b0; // input
wire app_zq_req = 1'b0; // input
wire app_sr_active; // output
wire app_ref_ack; // output
wire app_zq_ack; // output

wire ui_clk; // output
wire ui_clk_sync_rst; // output
wire mclk = ui_clk;
wire mrst_n = ~ui_clk_sync_rst;
//wire mclk = clk;
//wire mrst_n = rst_n;
//wire clk = ui_clk;
//wire rst_n = ui_clk_sync_rst;

wire init_calib_complete; // output
wire [11:0] device_temp; // output
wire calib_tap_req; // output
wire calib_tap_load = 1'b0; // input
wire [6:0] calib_tap_addr = 7'd0; // input
wire [7:0] calib_tap_val = 8'd0; // input
wire calib_tap_load_done = 1'b0; // input
wire sys_rst = rst_n; // input

mig_7series_0 mig_7series_0 (
	.ddr3_dq(ddr3_dq),
	.ddr3_dqs_n(ddr3_dqs_n),
	.ddr3_dqs_p(ddr3_dqs_p),
	.ddr3_addr(ddr3_addr),
	.ddr3_ba(ddr3_ba),
	.ddr3_ras_n(ddr3_ras_n),
	.ddr3_cas_n(ddr3_cas_n),
	.ddr3_we_n(ddr3_we_n),
	.ddr3_reset_n(ddr3_reset_n),
	.ddr3_ck_p(ddr3_ck_p),
	.ddr3_ck_n(ddr3_ck_n),
	.ddr3_cke(ddr3_cke),
	.ddr3_cs_n(ddr3_cs_n),
	.ddr3_dm(ddr3_dm),
	.ddr3_odt(ddr3_odt),
	.sys_clk_i(sys_clk_i),
	.clk_ref_i(clk_ref_i),
	.app_addr(app_addr),
	.app_cmd(app_cmd),
	.app_en(app_en),
	.app_wdf_data(app_wdf_data),
	.app_wdf_end(app_wdf_end),
	.app_wdf_mask(app_wdf_mask),
	.app_wdf_wren(app_wdf_wren),
	.app_rd_data(app_rd_data),
	.app_rd_data_end(app_rd_data_end),
	.app_rd_data_valid(app_rd_data_valid),
	.app_rdy(app_rdy),
	.app_wdf_rdy(app_wdf_rdy),
	.app_sr_req(app_sr_req),
	.app_ref_req(app_ref_req),
	.app_zq_req(app_zq_req),
	.app_sr_active(app_sr_active),
	.app_ref_ack(app_ref_ack),
	.app_zq_ack(app_zq_ack),
	.ui_clk(ui_clk),
	.ui_clk_sync_rst(ui_clk_sync_rst),
	.init_calib_complete(init_calib_complete),
	.device_temp(device_temp),
	//.calib_tap_req(calib_tap_req),
	//.calib_tap_load(calib_tap_load),
	//.calib_tap_addr(calib_tap_addr),
	//.calib_tap_val(calib_tap_val),
	//.calib_tap_load_done(calib_tap_load_done),
	.sys_rst(sys_rst)
	);



/*

dummy_mig dummy_mig (
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
	.app_rd_data_valid(app_rd_data_valid)
	);

*/

uart_top #(.DWIDTH(DWIDTH)) uart_top (
	.clk(clk),
	.rst_n(rst_n),
	.rx(rx),
	.tx(tx),
	.d_ram_radr(rin_addr),
	.d_ram_wadr(win_addr),
	.d_ram_rdata(rdat_m_data),
	.d_ram_wdata(in_wdata),
	.d_ram_wen(wstart_rq),
	.d_read_sel(d_read_sel),
	.d_ram_mask(in_mask),
	.dread_start(rstart_rq),
	.read_valid(rdat_m_valid),
	.i_ram_radr(i_ram_radr),
	.i_ram_wadr(i_ram_wadr),
	.i_ram_rdata(i_ram_rdata),
	.i_ram_wdata(i_ram_wdata),
	.i_ram_wen(i_ram_wen),
	.i_read_sel(i_read_sel),
	.pc_data(pc_data),
	.cpu_start(cpu_start),
	.quit_cmd(quit_cmd),
	.start_adr(start_adr)
	
	);

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
	.wstrb(wstrb),
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
	.wstrb(wstrb),
	.wlast(wlast),
	.bvalid(bvalid),
	.bready(bready),
	.bid(bid),
	.bcomp(bcomp),
	.wstart_rq(wstart_rq),
	.win_addr(win_addr),
	.in_wdata(in_wdata),
	.in_mask(in_mask),
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

lchika lchika (
	.mclk(mclk),
	.mrst_n(mrst_n),
	.rgb_led(rgb_led)
	);

endmodule
