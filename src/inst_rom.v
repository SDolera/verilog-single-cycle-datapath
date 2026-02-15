`timescale 1ns / 1ps
module inst_rom (
    input  wire        clock,
    input  wire        reset,
    input  wire        en,
    input  wire [31:0] addr_in,
    output wire [31:0] data_out
);
    parameter ADDR_WIDTH   = 8;
    parameter INIT_PROGRAM = "";
    parameter ROM_BASE_PC  = 32'h0040_0000;

    reg [31:0] rom [0:(1<<ADDR_WIDTH)-1];
    reg [31:0] out;
    integer k;

    wire [31:0] pc_off  = addr_in - ROM_BASE_PC;
    wire [ADDR_WIDTH-1:0] rom_idx = pc_off[ADDR_WIDTH+1:2];

    // swap bytes on output only
    assign data_out = {out[7:0], out[15:8], out[23:16], out[31:24]};

    initial begin
        for (k = 0; k < (1<<ADDR_WIDTH); k = k + 1)
            rom[k] = 32'h00000000;
        $readmemh(INIT_PROGRAM, rom);
    end

    // pick posedge/negedge to match your timing choice
    always @(negedge clock) begin
        if (reset) out <= 32'h00000000;
        else if (en) begin
            if (addr_in < ROM_BASE_PC) out <= 32'h00000000;
            else out <= rom[rom_idx];
        end
    end
endmodule
