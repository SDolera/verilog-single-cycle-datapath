`timescale 1ns/1ps

module sign_extender_tb;

    reg  [15:0] in;
    wire [31:0] out;

    sign_extender dut (
        .in(in),
        .out(out)
    );

    initial begin
        $display("=== sign_extend_16_32_tb start ===");

        // Positive value (MSB=0)
        in = 16'h7FFF; #1;
        $display("in=7FFF -> out=%h (expect 00007FFF)", out);

        // Negative value (MSB=1)
        in = 16'h8000; #1;
        $display("in=8000 -> out=%h (expect FFFF8000)", out);

        // -1
        in = 16'hFFFF; #1;
        $display("in=FFFF -> out=%h (expect FFFFFFFF)", out);

        $display("=== sign_extend_16_32_tb done ===");
        $finish;
    end

endmodule
