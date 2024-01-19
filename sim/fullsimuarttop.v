/*
 * My RISC-V RV32I CPU
 *   Verilog Simulation Top Module
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2024 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module fullsimuarttop;

reg clkin;
reg rst_n;
wire rx;
wire tx;

fpga_dram_top fpga_top (
        .clkin(clkin),
        .rst_n(rst_n),
		.rx(rx),
        .tx(tx)
	);

initial clkin = 0;

always #5 clkin <= ~clkin;


initial begin
	rst_n = 1'b1;
#10
	rst_n = 1'b0;
#20
	rst_n = 1'b1;
#500000
	$stop;
end

// data sender
reg [5:0] timer;

always @ (posedge clkin or negedge rst_n) begin
    if (~rst_n)
        timer <= 6'd19 ;
    else if ( timer == 6'd0 )
        timer <= 6'd19 ;
    else
        timer <= timer - 6'd1 ;
end

wire trg = ( timer == 6'd0);


reg [381:0] data;
always @ (posedge clkin or negedge rst_n) begin
    if (~rst_n)
        data <= { 3'b110, 8'h8e, 2'b10, 8'h04, 2'b10, 8'hee, 2'b10,
                          8'h0c, 2'b10, 8'h0c, 2'b10, 8'h0c, 2'b10, 8'h0c, 2'b10,
                          8'h0c, 2'b10, 8'h0c, 2'b10, 8'h0c, 2'b10, 8'h0c, 2'b10,
                          8'hcc, 2'b10, 8'hcc, 2'b10, 8'hcc, 2'b10, 8'hcc, 2'b10,
                          8'hcc, 2'b10, 8'hcc, 2'b10, 8'hcc, 2'b10, 8'hcc, 2'b10,
                          8'h8e, 2'b10, 8'h04, 2'b10, 8'h4e, 2'b10,
                          8'h0c, 2'b10, 8'h0c, 2'b10, 8'h0c, 2'b10, 8'h0c, 2'b10,
                          8'h0c, 2'b10, 8'h0c, 2'b10, 8'h0c, 2'b10, 8'h0c, 2'b10,
                          8'h0c, 2'b10, 8'h0c, 2'b10, 8'h0c, 2'b10, 8'h0c, 2'b10,
                          8'h0c, 2'b10, 8'h0c, 2'b10, 8'h4c, 2'b10, 8'h0c, 1'b1 };
    else if ( trg )
        data <= { data[380:0], 1'b1};
end

assign rx = data[381];

endmodule
