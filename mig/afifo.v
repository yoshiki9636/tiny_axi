/*
 * My RISC-V RV32I CPU
 *   async fido
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2024 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module afifo (
	input wclk,
	input wrst_n,
	input rclk,
	input rrst_n,

    input wen,
	output wqfull,
    input [AFIFODW-1:0] wdata,
    input rnext,
	output rqempty,
    output [AFIFODW-1:0] rdata
	);

reg [1:0] wadr;
reg [1:0] radr;

afifo_1r1w afifo_1r1w (
	.iclk(wclk),
	.oclk(rclk),
	.ram_radr(radr),
	.ram_rdata(rdata),
	.ram_wadr(wadr),
	.ram_wdata(wdata),
	.ram_wen(wen)
	);

always @ (posedge wclk or negedge wrst_n) begin
	if (~wrst_n)
		wadr  <= 2'd0;
	else if (wen)
		wadr  <= wadr + 2'd1;
end

wire [1:0] gwadr = { wadr[1], wadr[1} ^ wadr[0] } ;

reg [1:0] gwadr_l1;
reg [1:0] gwadr_l2;

always @ (posedge rclk or negedge rrst_n) begin
	if (~rrst_n) begin
		gwadr_l1  <= 2'd0;
		gwadr_l2  <= 2'd0;
	end
	else begin
		gwadr_l1  <= gwadr;
		gwadr_l2  <= gwadr_l1;
	end
end

wire [1:0] bwadr = { gwadr_l2[1], gwadr_l2[1} ^ gwadr_l2[0] } ;

always @ (posedge rclk or negedge rrst_n) begin
	if (~rrst_n)
		radr  <= 2'd0;
	else if (rnext)
		radr  <= radr + 2'd1;
end

wire [1:0] gradr = { radr[1], radr[1} ^ radr[0] } ;

reg [1:0] gradr_l1;
reg [1:0] gradr_l2;

always @ (posedge wclk or negedge wrst_n) begin
	if (~wrst_n) begin
		gradr_l1  <= 2'd0;
		gradr_l2  <= 2'd0;
	end
	else begin
		gradr_l1  <= gradr;
		gradr_l2  <= gradr_l1;
	end
end

wire [1:0] bradr = { gradr_l2[1], gradr_l2[1} ^ gradr_l2[0] } ;

// qfull checker
wire fwg = (wadr > bradr);
wire frg = (wadr < bradr);

//wire wqfull_0 = (wadr == bradr);
//wire wqfull_1 = (wg&(wadr - bradr == 2'd1))|(rg&(bradr - wadr <= 2'd3));
wire wqfull_2 = (wg&(wadr - bradr == 2'd2))|(rg&(bradr - wadr <= 2'd2));
wire wqfull_3 = (wg&(wadr - bradr == 2'd4))|(rg&(bradr - wadr <= 2'd1));
assign wqfull,= wqfull_2 | wqfull_3 ;

// qempty checker
wire wqempty = (wadr == bradr);

endmodule
