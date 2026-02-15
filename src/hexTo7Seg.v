module hexTo7Seg(
    input [3:0] x,  // 4-bit input to represent hexadecimal digits
    output reg [6:0] z  // 7-bit output for 7-segment display
);

always @(*) begin
    case (x)
        4'b0000: z = 7'b1000000; // 0
        4'b0001: z = 7'b1111001; // 1
        4'b0010: z = 7'b0100100; // 2
        4'b0011: z = 7'b0110000; // 3
        4'b0100: z = 7'b0011001; // 4
        4'b0101: z = 7'b0010010; // 5
        4'b0110: z = 7'b0000010; // 6
        4'b0111: z = 7'b1111000; // 7
        4'b1000: z = 7'b0000000; // 8
        4'b1001: z = 7'b0010000; // 9
        4'b1010: z = 7'b0001000; // A
        4'b1011: z = 7'b0000011; // b
        4'b1100: z = 7'b1000110; // C
        4'b1101: z = 7'b0100001; // d
        4'b1110: z = 7'b0000110; // E
        4'b1111: z = 7'b0001110; // F
        default: z = 7'b1111111; // Blank display for invalid input
    endcase
end

endmodule