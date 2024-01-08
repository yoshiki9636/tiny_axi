/*
 * My RISC-V RV32I CPU
 *   request queue
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2024 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module req_queue (
	input clk,
	input rst_n,

    input wcmd_wen,
    input rcmd_wen,
	output wcmd_ack,
	output rcmd_ack,
    input [31:0] waddr,
    input [31:0] raddr,
    input rnext,
	output rqempty,
    output [31:0] qraddr,
    output rd_bwt
	);

reg [2:0] wadr;
reg [2:0] radr;
wire [32:0] qw_rd_bwt_addr;
wire [32:0] qr_rd_bwt_addr;

// assume no back-to-back request on write
reg [31:0] wadr_keeper;
reg collision_selw;
wire wqfull;

wire collision = wcmd_wen & rcmd_wen;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		collision_selw  <= 1'b0;
	else if (collision)
		collision_selw  <= ~collision_selw;
	else if (rcmd_wen)
		collision_selw  <= 1'b0;
	else if (wcmd_wen)
		collision_selw  <= 1'b1;
	else
		collision_selw  <= 1'b0;
end

assign selr = (collision ? ~collision_selw : rcmd_wen) & ~wqfull;
assign selw = (collision ?  collision_selw : wcmd_wen) & ~wqfull;

assign qr_rd_bwt_addr = selr ? { 1'b1, raddr } :
                        selw ? { 1'b0, waddr } : 33'd0;

wire qwen = (rcmd_wen | rcmd_wen) & ~wqfull;

assign wcmd_ack = selr;
assign rcmd_ack = selw;

sfifo_1r1w
	#(.SFIFODW(33),
	  .SFIFOAW(3),
	  .SFIFODP(8)
	) sfifo_1r1w (
	.clk(clk),
	.ram_radr(radr),
	.ram_rdata(qr_rd_bwt_addr),
	.ram_wadr(wadr),
	.ram_wdata(qw_rd_bwt_addr),
	.ram_wen(qwen)
	);

assign qraddr = qr_rd_bwt_addr[31:0];
assign rd_bwt = qr_rd_bwt_addr[32];

// fifo controls

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		wadr  <= 2'd0;
	else if (wen)
		wadr  <= wadr + 2'd1;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		radr  <= 2'd0;
	else if (rnext)
		radr  <= radr + 2'd1;
end

// qfull checker
wire fwg = (wadr > radr);
wire frg = (wadr < radr);

//wire wqfull_0 = (wadr == radr);
//wire wqfull_1 = (wg&(wadr - radr == 2'd1))|(rg&(radr - wadr <= 2'd3));
wire wqfull_2 = (wg&(wadr - radr == 2'd2))|(rg&(radr - wadr <= 2'd2));
wire wqfull_3 = (wg&(wadr - radr == 2'd4))|(rg&(radr - wadr <= 2'd1));
assign wqfull,= wqfull_2 | wqfull_3 ;

// qempty checker
wire wqempty = (wadr == radr);

endmodule
