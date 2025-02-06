`include "ALU.v"
`include "Registradores.v"
`include "ControlUnit.v"
`include "ALUControl.v"

module MIPS_Single_Cycle(
    input wire clk,
    input wire reset
);

    wire RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, Jump;
    wire [1:0] ALUOp;

    wire [31:0] PC, NextPC, Instruction, ReadData1, ReadData2, ALUResult, WriteData, SignExtend, ALUInput2, MemData;
    wire [4:0] WriteRegister;
    wire Zero, PCSrc;

    reg [31:0] InstructionMemory [0:1023]; 
    initial $readmemh("program.hex", InstructionMemory); 

    reg [31:0] DataMemory [0:1023]; 
    initial $readmemh("data.hex", DataMemory); 

    reg [31:0] PC;
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 32'b0;
        else
            PC <= NextPC;
    end

    assign Instruction = InstructionMemory[PC >> 2]; // PC é byte address, memória é word address

    ControlUnit control (
        .Opcode(Instruction[31:26]),
        .RegDst(RegDst),
        .ALUSrc(ALUSrc),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .ALUOp(ALUOp),
        .Jump(Jump)
    );

    Registradores regfile (
        .ReadRegister1(Instruction[25:21]),
        .ReadRegister2(Instruction[20:16]),
        .WriteRegister(WriteRegister),
        .WriteData(WriteData),
        .RegWrite(RegWrite),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );

    assign SignExtend = { {16{Instruction[15]}}, Instruction[15:0] };

    assign ALUInput2 = ALUSrc ? SignExtend : ReadData2;

    ALU alu (
        .A(ReadData1),
        .B(ALUInput2),
        .ALUOperation(ALUControl),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );

    assign WriteRegister = RegDst ? Instruction[15:11] : Instruction[20:16];

    assign MemData = DataMemory[ALUResult >> 2]; 
    always @(posedge clk) begin
        if (MemWrite)
            DataMemory[ALUResult >> 2] <= ReadData2; 
    end

    assign WriteData = MemtoReg ? MemData : ALUResult;

    ALUControl alu_control (
        .ALUOp(ALUOp),
        .Funct(Instruction[5:0]),
        .ALUOperation(ALUControl)
    );

    assign PCSrc = Branch & Zero;
    assign NextPC = Jump ? {PC[31:28], Instruction[25:0], 2'b00} : 
                    PCSrc ? PC + 4 + (SignExtend << 2) : 
                    PC + 4; 

endmodule