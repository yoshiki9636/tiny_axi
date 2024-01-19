/*
 * My RISC-V RV32I CPU
 *   async fido
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2024 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module lchika (
	input mclk,
	input mrst_n,
	output [2:0] rgb_led

	);

reg [31:0] cntr;

always @ (posedge mclk or negedge mrst_n) begin
	if (~mrst_n)
		cntr  <= 32'd0;
	else
		cntr  <= cntr + 32'd1;
end

assign rgb_led = cntr[28:26];

endmodule
