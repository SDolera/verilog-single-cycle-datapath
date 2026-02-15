`timescale 1ns/1ps

module pc_register_tb;

    reg        clock;
    reg        reset;
    reg [31:0] next_pc;
    wire [31:0] pc;

    pc_register dut (
        .clock(clock),
        .reset(reset),
        .next_pc(next_pc),
        .pc(pc)
    );

    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    initial begin
        $display("=== pc_reg_tb start ===");
        reset   = 1;
        next_pc = 32'h0000_0000;

        #12;       // allow some time
        reset = 0;

        // 1) First update
        next_pc = 32'h0000_0004;
        @(posedge clock); #1;
        $display("PC=%h (expect 00000004)", pc);

        // 2) Next update
        next_pc = 32'h0000_0010;
        @(posedge clock); #1;
        $display("PC=%h (expect 00000010)", pc);

        // 3) Reset again
        reset = 1;
        @(posedge clock); #1;
        reset = 0;
        $display("After reset: PC=%h (expect 00000000)", pc);

        $display("=== pc_reg_tb done ===");
        $finish;
    end

endmodule
