`timescale 1ns/1ps

module testbench;

  // =====================================================
  // Clock / Reset
  // =====================================================
  reg clock;
  reg reset;

  initial begin
    clock = 1'b0;
    forever #10 clock = ~clock;   // 50 MHz
  end

  initial begin
    reset = 1'b1;
    #200 reset = 1'b0;
  end

  initial begin
    #5000 $finish;   // adjust as needed
  end

  // =====================================================
  // Wires for processor I/O
  // =====================================================
  wire step_en = 1'b1;   // free-run in simulation

  wire [7:0] serial_out;
  wire       serial_wren;
  wire       serial_rden;

  // Debug outputs
  wire [31:0] pc_out;
  wire [31:0] instruction_out;
  wire [31:0] regA_out;
  wire [31:0] regB_out;
  wire [31:0] aluB_out;
  wire [31:0] alu_out_out;
  wire [31:0] mem_rdata_out;
  wire [31:0] write_data_out;
  wire [4:0]  write_reg_out;

  wire RegWrite_out;
  wire MemWrite_out;
  wire MemRead_out;
  wire ALUSrc_out;
  wire MemtoReg_out;
  wire RegDst_out;
  wire [5:0] ALUFunc_out;

  // =====================================================
  // Instantiate processor (DUT)
  // =====================================================
  processor dut (
    .clock(clock),
    .reset(reset),
    .step_en(step_en),

    .serial_in(8'b0),
    .serial_ready_in(1'b1),
    .serial_valid_in(1'b0),
    .serial_rden_out(serial_rden),
    .serial_out(serial_out),
    .serial_wren_out(serial_wren),

    // debug ports
    .pc_out(pc_out),
    .instruction_out(instruction_out),
    .regA_out(regA_out),
    .regB_out(regB_out),
	 .aluB_out(aluB_out),
    .alu_out_out(alu_out_out),
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
  // Every-cycle status line (screenshot-style)
  // =====================================================
  always @(negedge clock) begin
    if (!reset) begin
      #1 $display(
        "Time:%0t | PC:%h | Instr:%h | ALU A:%h | ALU B:%h | ALU Out:%h | Serial:%c | WREN:%b",
        $time,
        pc_out,
        instruction_out,
        regA_out,
        aluB_out,
        alu_out_out,
        serial_out,
        serial_wren
      );
    end
  end

  // =====================================================
  // Optional: extra serial write line
  // =====================================================
  always @(posedge clock) begin
    if (!reset && serial_wren) begin
      #1 $display(">>> Serial Write: %c (ASCII %0d)", serial_out, serial_out);
    end
  end

endmodule
