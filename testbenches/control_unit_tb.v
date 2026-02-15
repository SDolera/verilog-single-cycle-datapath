`timescale 1ns/1ps

module control_unit_tb;

    // Inputs
    reg  [5:0] opcode;
    reg  [5:0] funct;

    // Outputs
    wire       RegDst;
    wire       RegWrite;
    wire       ALUSrc;
    wire       MemRead;
    wire       MemWrite;
    wire       MemtoReg;
    wire [5:0] ALUFunc;

    integer errors;

    // DUT
    control_unit dut (
        .opcode(opcode),
        .funct(funct),
        .RegDst(RegDst),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .ALUFunc(ALUFunc)
    );

    // Pretty print current state
    task show;
        input [127:0] name;
        begin
            $display("%0t  %-10s opcode=%b funct=%b | RegDst=%b RegWrite=%b ALUSrc=%b MemRead=%b MemWrite=%b MemtoReg=%b ALUFunc=%b",
                     $time, name, opcode, funct,
                     RegDst, RegWrite, ALUSrc, MemRead, MemWrite, MemtoReg, ALUFunc);
        end
    endtask

    // Check helper (compares actual vs expected)
    task check;
        input [127:0] name;
        input exp_RegDst, exp_RegWrite, exp_ALUSrc, exp_MemRead, exp_MemWrite, exp_MemtoReg;
        input [5:0] exp_ALUFunc;
        begin
            #1; // allow combinational logic to settle

            if (RegDst   !== exp_RegDst  ||
                RegWrite !== exp_RegWrite||
                ALUSrc   !== exp_ALUSrc  ||
                MemRead  !== exp_MemRead ||
                MemWrite !== exp_MemWrite||
                MemtoReg !== exp_MemtoReg||
                ALUFunc  !== exp_ALUFunc) begin

                $display("FAIL: %s", name);
                show("ACTUAL");
                $display("      EXPECTED: RegDst=%b RegWrite=%b ALUSrc=%b MemRead=%b MemWrite=%b MemtoReg=%b ALUFunc=%b",
                         exp_RegDst, exp_RegWrite, exp_ALUSrc, exp_MemRead, exp_MemWrite, exp_MemtoReg, exp_ALUFunc);
                errors = errors + 1;
            end else begin
                $display("PASS: %s", name);
                show("OK");
            end
            $display("");
        end
    endtask

    initial begin
        errors = 0;

        $display("=== control_unit TB start ===\n");

        // ----------------------------
        // R-type opcode = 000000
        // Expect:
        // RegDst=1 RegWrite=1 ALUSrc=0 MemRead=0 MemWrite=0 MemtoReg=0 ALUFunc=funct
        // ----------------------------
        opcode = 6'b000000;

        funct = 6'b100000; #5; // ADD
        check("R-ADD", 1,1,0,0,0,0, 6'b100000);

        funct = 6'b100010; #5; // SUB
        check("R-SUB", 1,1,0,0,0,0, 6'b100010);

        funct = 6'b100100; #5; // AND
        check("R-AND", 1,1,0,0,0,0, 6'b100100);

        funct = 6'b100101; #5; // OR
        check("R-OR",  1,1,0,0,0,0, 6'b100101);

        funct = 6'b100110; #5; // XOR
        check("R-XOR", 1,1,0,0,0,0, 6'b100110);

        funct = 6'b100111; #5; // NOR
        check("R-NOR", 1,1,0,0,0,0, 6'b100111);

        // ----------------------------
        // LW opcode = 100011
        // Expect:
        // RegDst=0 RegWrite=1 ALUSrc=1 MemRead=1 MemWrite=0 MemtoReg=1 ALUFunc=ADD
        // ----------------------------
        opcode = 6'b100011; funct = 6'bxxxxxx; #5;
        check("LW", 0,1,1,1,0,1, 6'b100000);

        // ----------------------------
        // SW opcode = 101011
        // Expect:
        // RegWrite=0 ALUSrc=1 MemWrite=1 others 0, ALUFunc=ADD
        // ----------------------------
        opcode = 6'b101011; funct = 6'bxxxxxx; #5;
        check("SW", 0,0,1,0,1,0, 6'b100000);

        // ----------------------------
        // ADDI opcode = 001000
        // Expect:
        // RegDst=0 RegWrite=1 ALUSrc=1 MemtoReg=0 MemRead=0 MemWrite=0 ALUFunc=ADD
        // ----------------------------
        opcode = 6'b001000; funct = 6'bxxxxxx; #5;
        check("ADDI", 0,1,1,0,0,0, 6'b100000);

        // ----------------------------
        // Unsupported opcode -> defaults (NOP-safe)
        // Expect:
        // All zeros except ALUFunc=ADD default
        // ----------------------------
        opcode = 6'b111111; funct = 6'b000000; #5;
        check("UNSUPPORTED", 0,0,0,0,0,0, 6'b100000);

        // Summary
        if (errors == 0)
            $display("=== ALL TESTS PASSED ===");
        else
            $display("=== TESTS FAILED: %0d errors ===", errors);

        $finish;
    end

endmodule
