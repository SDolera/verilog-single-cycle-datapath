`timescale 1ns/1ps

module mux_tb;

    reg  [31:0] in0, in1;
    reg         sel;
    wire [31:0] out;

    // 32-bit mux
    mux #(.WIDTH(32)) dut (
        .in0(in0),
        .in1(in1),
        .sel(sel),
        .out(out)
    );

    initial begin
        $display("=== mux2_tb start ===");
        in0 = 32'hAAAA_AAAA;
        in1 = 32'h5555_5555;

        sel = 0; #1;
        $display("sel=0 -> out=%h (expect AAAA_AAAA)", out);

        sel = 1; #1;
        $display("sel=1 -> out=%h (expect 5555_5555)", out);

        // change inputs
        in0 = 32'h1234_5678;
        in1 = 32'hDEAD_BEEF;

        sel = 0; #1;
        $display("sel=0 -> out=%h (expect 1234_5678)", out);

        sel = 1; #1;
        $display("sel=1 -> out=%h (expect DEAD_BEEF)", out);

        $display("=== mux2_tb done ===");
        $finish;
    end

endmodule
