`timescale 1ns / 1ps

module alu_control (
    input  wire [1:0] ALUOp,
    input  wire [5:0] funct,
    output reg  [5:0] ALUFunc
);

    always @(*) begin
        case (ALUOp)
            2'b00: ALUFunc = 6'b100000; // ADD (lw, sw, addi)
            2'b10: ALUFunc = funct;     // R-type: use funct field

            // Optional (future): branches like BEQ use SUB for compare
            // 2'b01: ALUFunc = 6'b100010; // SUB

            default: ALUFunc = 6'b100000; // safe default = ADD
        endcase
    end

endmodule
