`timescale 1ns / 1ps

module processor(
    input  wire        clock,
    input  wire        reset,

    input  wire [7:0]  serial_in,
    input  wire        serial_ready_in,
    input  wire        serial_valid_in,
    output wire        serial_rden_out,
    output wire [7:0]  serial_out,
    output wire        serial_wren_out,

    input  wire        step_en,

    // =====================================================
    // DEBUG OUTPUT PORTS (for DE1-SoC HEX/LED demo)
    // =====================================================
    output wire [31:0] pc_out,
    output wire [31:0] instruction_out,
    output wire [31:0] regA_out,
    output wire [31:0] regB_out,
	 output wire [31:0] aluB_out,
    output wire [31:0] alu_out_out,
    output wire [31:0] mem_rdata_out,
    output wire [31:0] write_data_out,
    output wire [4:0]  write_reg_out,

    output wire        RegWrite_out,
    output wire        MemWrite_out,
    output wire        MemRead_out,
    output wire        ALUSrc_out,
    output wire        MemtoReg_out,
    output wire        RegDst_out,
    output wire [5:0]  ALUFunc_out
);

    // =====================================================
    // PC + Instruction Fetch
    // =====================================================
    wire [31:0] pc, pc_plus4, next_pc;
    wire [31:0] instr;

    pc_register #(.RESET_PC(32'h003F_FFFC)) PC (
        .clk(clock),
        .reset(reset),
        .en(step_en),
        .next_pc(next_pc),
        .pc(pc)
    );

    adder PC_ADD (
        .a(pc),
        .b(32'd4),
        .y(pc_plus4)
    );

    // Simple core: no branch/jump yet
    assign next_pc = pc_plus4;

    inst_rom #(
        .ADDR_WIDTH(8),
        //.INIT_PROGRAM("hello.memh"),
		  .INIT_PROGRAM("nbhelloworld.memh"),
		  .ROM_BASE_PC(32'h0040_0000)
    ) IROM (
        .clock(clock),
        .reset(reset),
        //.en(step_en),
		  .en(1'b1),
        .addr_in(pc),
        .data_out(instr)
    );

    // =====================================================
    // Instruction Decode
    // =====================================================
    wire [5:0] opcode = instr[31:26];
    wire [4:0] rs     = instr[25:21];
    wire [4:0] rt     = instr[20:16];
    wire [4:0] rd     = instr[15:11];
    wire [15:0] imm16 = instr[15:0];
    wire [5:0] funct  = instr[5:0];

    // =====================================================
    // Control Signals (from separate control_unit)
    // =====================================================
    wire        RegDst;
    wire        RegWrite;
    wire        ALUSrc;
    wire        MemRead;
    wire        MemWrite;
    wire        MemtoReg;
    wire [5:0]  ALUFunc;   // goes directly into alu.v
	 wire [1:0]  alu_op;

    control_unit CU (
        .opcode(opcode),
        //.funct(funct),
        .RegDst(RegDst),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        //.ALUFunc(ALUFunc)
		  .ALUOp(alu_op)
    );
	 
	 // ALU control: ALUOp + funct -> ALUFunc
	 alu_control ALUCTRL (
		 .ALUOp(alu_op),
		 .funct(funct),
		 .ALUFunc(ALUFunc)
	 );

    // =====================================================
    // Register File
    // =====================================================
    wire [31:0] regA, regB;
    wire [31:0] write_data;
    wire [4:0]  write_reg;
    wire        RegWrite_g = RegWrite & step_en;

    register_file RF (
        .clk(clock),
        .reset(reset),
        .ra1(rs),
        .ra2(rt),
        .rd1(regA),
        .rd2(regB),
        .we(RegWrite_g),
        .wa(write_reg),
        .wd(write_data)
    );

    // Destination register mux (rt vs rd)
    mux #(.WIDTH(5)) REGDST_MUX (
        .d0(rt),
        .d1(rd),
        .s(RegDst),
        .y(write_reg)
    );

    // =====================================================
    // Immediate + ALU
    // =====================================================
    wire [31:0] imm32;
    sign_extender SIGNEXT (
        .imm16(imm16),
        .imm32(imm32)
    );

    wire [31:0] aluB;
    mux #(.WIDTH(32)) ALUSRC_MUX (
        .d0(regB),
        .d1(imm32),
        .s(ALUSrc),
        .y(aluB)
    );

    wire [31:0] alu_out;
    wire alu_branch, alu_jump; // unused in simple core

    alu ALU (
        .Func_in(ALUFunc),
        .A_in(regA),
        .B_in(aluB),
        .O_out(alu_out),
        .Branch_out(alu_branch),
        .Jump_out(alu_jump)
    );

    // =====================================================
    // Data Memory
    // =====================================================
    wire [31:0] mem_rdata;
    wire MemWrite_g = MemWrite & step_en;
    wire MemRead_g  = MemRead  & step_en;

    data_memory #(
        .INIT_PROGRAM0("D:\\COE181\\datapathImplementation\\blank.memh"),
        .INIT_PROGRAM1("D:\\COE181\\datapathImplementation\\blank.memh"),
        .INIT_PROGRAM2("D:\\COE181\\datapathImplementation\\blank.memh"),
        .INIT_PROGRAM3("D:\\COE181\\datapathImplementation\\blank.memh")
    ) DMEM (
        .clock(clock),
        .reset(reset),
        .addr_in(alu_out),
        .writedata_in(regB),
        .re_in(MemRead_g),
        .we_in(MemWrite_g),
        .size_in(2'b11),          // word access
        .readdata_out(mem_rdata),

        .serial_in(serial_in),
        .serial_ready_in(serial_ready_in),
        .serial_valid_in(serial_valid_in),
        .serial_out(serial_out),
        .serial_rden_out(serial_rden_out),
        .serial_wren_out(serial_wren_out)
    );

    // Write-back mux
    mux #(.WIDTH(32)) MEMTOREG_MUX (
        .d0(alu_out),
        .d1(mem_rdata),
        .s(MemtoReg),
        .y(write_data)
    );

    // =====================================================
    // DEBUG OUTPUT ASSIGNMENTS (no behavior change)
    // =====================================================
    assign pc_out           = pc;
    assign instruction_out  = instr;
    assign regA_out         = regA;
    assign regB_out         = regB;
	 assign aluB_out 			 = aluB;
    assign alu_out_out      = alu_out;
    assign mem_rdata_out    = mem_rdata;
    assign write_data_out   = write_data;
    assign write_reg_out    = write_reg;

    assign RegWrite_out     = RegWrite;
    assign MemWrite_out     = MemWrite;
    assign MemRead_out      = MemRead;
    assign ALUSrc_out       = ALUSrc;
    assign MemtoReg_out     = MemtoReg;
    assign RegDst_out       = RegDst;
    assign ALUFunc_out      = ALUFunc;

endmodule
