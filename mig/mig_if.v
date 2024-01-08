/*
 * My RISC-V RV32I CPU
 *   dram mig interface
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2024 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module mig_if (
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


	);




endmodule
