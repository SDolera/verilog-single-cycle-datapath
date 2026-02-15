`timescale 1ns / 1ps

module register_file(
    input  wire        clk,
    input  wire        reset,

    input  wire [4:0]  ra1,
    input  wire [4:0]  ra2,
    output wire [31:0] rd1,
    output wire [31:0] rd2,

    input  wire        we,
    input  wire [4:0]  wa,
    input  wire [31:0] wd
);

reg [31:0] regs[0:31];
integer i;

// async reads, with $zero hard-wired to 0
assign rd1 = (ra1 == 5'd0) ? 32'd0 : regs[ra1];
assign rd2 = (ra2 == 5'd0) ? 32'd0 : regs[ra2];

always @(posedge clk) begin
    if (reset) begin
        for (i=0; i<32; i=i+1) regs[i] <= 32'd0;
    end else begin
        if (we && (wa != 5'd0))
            regs[wa] <= wd;
        regs[0] <= 32'd0; // enforce $zero
    end
end

endmodule
