`timescale 1ns/1ps

module adder_tb;

    reg  [31:0] a, b;
    wire [31:0] y;

    adder #(.WIDTH(32)) dut (
        .a(a),
        .b(b),
        .y(y)
    );

    initial begin
        $display("=== adder_tb start ===");

        a = 32'd0;    b = 32'd4;    #1;
        $display("0 + 4   = %0d (expect 4)", y);

        a = 32'd10;   b = 32'd20;   #1;
        $display("10 + 20 = %0d (expect 30)", y);

        a = 32'hFFFF_FFFF; b = 32'd1; #1;
        $display("FFFFFFFF + 1 = %h (expect 00000000 due to wrap)", y);

        $display("=== adder_tb done ===");
        $finish;
    end

endmodule
