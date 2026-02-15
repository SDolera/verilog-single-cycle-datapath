`timescale 1ns/1ps

module wrapper (
    input  wire        CLOCK_50,        // DE1-SoC 50 MHz clock
    input  wire [9:0]  SW,
    input  wire [3:0]  KEY,

    output wire [9:0]  LEDR,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5
);

    // =====================================================
    // Reset / Step (KEYs are active-low on DE1-SoC)
    // =====================================================
    wire reset_n = KEY[0];          // not pressed = 1
    wire step_n  = KEY[1];

    wire [7:0]  serial_out;
    wire        serial_wren;

    // Sync reset (KEY0 is async)
    reg [1:0] rst_sync = 2'b11;
    always @(posedge CLOCK_50) rst_sync <= {rst_sync[0], reset_n};
    wire reset = ~rst_sync[1];      // active-high reset into CPU

    // =====================================================
    // 1-pulse-per-press step generator (simple debouncer)
    // =====================================================
    reg [19:0] db_cnt = 20'd0;      // ~10-20ms at 50MHz depending on width
    reg step_sync0 = 1'b1, step_sync1 = 1'b1;
    reg step_stable = 1'b1;
    reg step_prev   = 1'b1;
    reg step_pulse  = 1'b0;

    // synchronize KEY1 to CLOCK_50
    always @(posedge CLOCK_50) begin
        step_sync0 <= step_n;
        step_sync1 <= step_sync0;
    end

    // debounce + generate pulse on falling edge (press)
    always @(posedge CLOCK_50) begin
        step_pulse <= 1'b0;

        if (reset) begin
            db_cnt      <= 20'd0;
            step_stable <= 1'b1;
            step_prev   <= 1'b1;
        end else begin
            if (step_sync1 != step_stable) begin
                db_cnt <= db_cnt + 1'b1;
                if (&db_cnt) begin
                    step_stable <= step_sync1;
                    db_cnt      <= 20'd0;
                end
            end else begin
                db_cnt <= 20'd0;
            end

            // pulse on press (stable goes 1 -> 0)
            step_prev <= step_stable;
            if (step_prev == 1'b1 && step_stable == 1'b0) begin
                step_pulse <= 1'b1;
            end
        end
    end

    // CPU clock + step enable
    wire cpu_clk = CLOCK_50;
    wire step_en = step_pulse;

    // =====================================================
    // LED pulse stretchers (for human-visible LEDs)
    // =====================================================
    reg [21:0] led9_cnt = 22'd0; // step indicator
    reg [21:0] led6_cnt = 22'd0; // serial write indicator

    always @(posedge CLOCK_50) begin
        if (reset) begin
            led9_cnt <= 22'd0;
            led6_cnt <= 22'd0;
        end else begin
            // Step pulse → stretch LED9
            if (step_pulse)
                led9_cnt <= 22'd2_500_000;   // ~50 ms
            else if (led9_cnt != 0)
                led9_cnt <= led9_cnt - 1'b1;

            // Serial write → stretch LED6
            if (serial_wren)
                led6_cnt <= 22'd2_500_000;   // ~50 ms
            else if (led6_cnt != 0)
                led6_cnt <= led6_cnt - 1'b1;
        end
    end

    // =====================================================
    // Processor DUT
    // =====================================================
    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] regA_out;
    wire [31:0] regB_out;
    wire [31:0] aluB_out;
    wire [31:0] alu_out;
    wire [31:0] mem_rdata_out;
    wire [31:0] write_data_out;
    wire [4:0]  write_reg_out;

    wire RegWrite_out, MemWrite_out, MemRead_out, ALUSrc_out, MemtoReg_out, RegDst_out;
    wire [5:0] ALUFunc_out;

    processor dut (
        .clock(cpu_clk),
        .reset(reset),
        .step_en(step_en),

        .serial_in(8'b0),
        .serial_ready_in(1'b1),
        .serial_valid_in(1'b0),
        .serial_rden_out(),
        .serial_out(serial_out),
        .serial_wren_out(serial_wren),

        // debug ports you add to processor.v
        .pc_out(pc_out),
        .instruction_out(instr_out),
        .regA_out(regA_out),
        .regB_out(regB_out),
        .aluB_out(aluB_out),
        .alu_out_out(alu_out),
        .mem_rdata_out(mem_rdata_out),
        .write_data_out(write_data_out),
        .write_reg_out(write_reg_out),

        .RegWrite_out(RegWrite_out),
        .MemWrite_out(MemWrite_out),
        .MemRead_out(MemRead_out),
        .ALUSrc_out(ALUSrc_out),
        .MemtoReg_out(MemtoReg_out),
        .RegDst_out(RegDst_out),
        .ALUFunc_out(ALUFunc_out)
    );

    // =====================================================
    // Select which 32-bit value to show
    // SW[2:0] = selector
    // SW[3]   = page (0=low24, 1=high24)
    // SW[4]   = override to show serial_out (and serial_wren flag)
    // =====================================================
    reg [31:0] view_bus;

    always @(*) begin
        // default: normal debug view
        case (SW[2:0])
            3'b000: view_bus = pc_out;
            3'b001: view_bus = instr_out;
            3'b010: view_bus = regA_out;
            3'b011: view_bus = aluB_out;
            3'b100: view_bus = alu_out;
            3'b101: view_bus = mem_rdata_out;
            3'b110: view_bus = write_data_out;
            3'b111: view_bus = {27'b0, write_reg_out};
            default: view_bus = 32'h0;
        endcase

        // NEW: SW[4] override: show serial byte (stable in your serial_buffer)
        // bit[8] = serial_wren pulse, bits[7:0] = serial_out byte
        if (SW[4]) begin
            view_bus = {23'b0, serial_wren, serial_out};
        end
    end

    wire page = SW[3];
    wire [23:0] view_24 = page ? view_bus[31:8] : view_bus[23:0];

    // =====================================================
    // HEX display (6 digits = 24 bits)
    // =====================================================
    hexTo7Seg h0(.x(view_24[3:0]),   .z(HEX0));
    hexTo7Seg h1(.x(view_24[7:4]),   .z(HEX1));
    hexTo7Seg h2(.x(view_24[11:8]),  .z(HEX2));
    hexTo7Seg h3(.x(view_24[15:12]), .z(HEX3));
    hexTo7Seg h4(.x(view_24[19:16]), .z(HEX4));
    hexTo7Seg h5(.x(view_24[23:20]), .z(HEX5));

    // =====================================================
    // LEDs (control/status)
    // =====================================================
    assign LEDR[0] = RegWrite_out;
    assign LEDR[1] = MemWrite_out;
    assign LEDR[2] = MemRead_out;
    assign LEDR[3] = ALUSrc_out;
    assign LEDR[4] = MemtoReg_out;
    assign LEDR[5] = RegDst_out;

    assign LEDR[6] = (led6_cnt != 0);   // visible serial activity
    assign LEDR[7] = reset;             // reset indicator
    assign LEDR[8] = page;              // page indicator (SW3)
    assign LEDR[9] = (led9_cnt != 0);   // visible step pulse

endmodule
