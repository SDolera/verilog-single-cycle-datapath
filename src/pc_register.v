`timescale 1ns / 1ps

module pc_register #(
    parameter RESET_PC = 32'h0040_0000
)(
    input  wire        clk,
    input  wire        reset,
	 input  wire        en,
    input  wire [31:0] next_pc,
    output reg  [31:0] pc
);
always @(posedge clk) begin
    if (reset)
        pc <= RESET_PC;
    else if (en)
        pc <= next_pc;
end
endmodule
