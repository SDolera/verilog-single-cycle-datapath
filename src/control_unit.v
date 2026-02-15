`timescale 1ns / 1ps

module control_unit (
    input  wire [5:0] opcode,

    output reg        RegDst,
    output reg        RegWrite,
    output reg        ALUSrc,
    output reg        MemRead,
    output reg        MemWrite,
    output reg        MemtoReg,
	 output reg [1:0]	 ALUOp
    // NEW: ALUOp (main control output)
    //output reg [1:0]  ALUOp
);

    always @(*) begin
        // Defaults = NOP-safe
        RegDst   = 1'b0;
        RegWrite = 1'b0;
        ALUSrc   = 1'b0;
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        MemtoReg = 1'b0;

        // Default ALUOp: "ADD" (safe for address calc / do-nothing style)
        ALUOp    = 2'b00;

        case (opcode)

            6'b000000: begin
                // R-type
                RegDst   = 1'b1;
                RegWrite = 1'b1;
                ALUSrc   = 1'b0;
                MemtoReg = 1'b0;
                ALUOp    = 2'b10;   // "use funct"
            end

            6'b100011: begin
                // LW
                RegDst   = 1'b0;
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                MemRead  = 1'b1;
                MemtoReg = 1'b1;
                ALUOp    = 2'b00;   // ADD (base + offset)
            end

            6'b101011: begin
                // SW
                RegWrite = 1'b0;
                ALUSrc   = 1'b1;
                MemWrite = 1'b1;
                ALUOp    = 2'b00;   // ADD (base + offset)
            end

            6'b001000: begin
                // ADDI
                RegDst   = 1'b0;
                RegWrite = 1'b1;
                ALUSrc   = 1'b1;
                MemtoReg = 1'b0;
                ALUOp    = 2'b00;   // ADD (rs + imm)
            end

            default: begin
                // Unsupported → NOP (keep defaults)
            end
        endcase
    end

endmodule
