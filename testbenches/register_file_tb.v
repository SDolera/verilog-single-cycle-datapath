`timescale 1ns / 1ps    // <-- add this line at the very top

module register_file_tb;

    reg clock, reset;
    reg [4:0] rr1, rr2, wr;
    reg [31:0] wd;
    reg we;
    wire [31:0] rd1, rd2;

    register_file dut (
        .clock(clock),
        .reset(reset),
        .read_reg1(rr1),
        .read_reg2(rr2),
        .read_data1(rd1),
        .read_data2(rd2),
        .write_reg(wr),
        .write_data(wd),
        .write_en(we)
    );

    initial begin
        clock = 0; forever #5 clock = ~clock;
    end

    initial begin
        reset = 1; #10; reset = 0;

        // write to reg5
        wr = 5; wd = 32'hDEADBEEF; we = 1;
        #10;

        // read it
        rr1 = 5; rr2 = 0;
        #1 $display("R5 = %h (expect DEADBEEF)", rd1);
        $display("R0 = %h (expect 0)", rd2);

        // attempt to write reg0
        wr = 0; wd = 32'hFFFFFFFF; we = 1;
        #10;

        rr1 = 0;
        #1 $display("R0 after write = %h (expect 0)", rd1);

        $finish;
    end

endmodule
