module MIPS_Single_Cycle(
    input wire clk,
    input wire reset
);

    wire RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, Jump;
    wire [1:0] ALUOp; // Por que não 5:0 ?

    wire [31:0] PC, Instruction, ReadData1, ReadData2, ALUResult, WriteData, SignExtend, ALUInput2;
    wire [4:0] WriteRegister;
    wire Zero;

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
        .Jump(Jump),
    );

    Registradores regfile (
        .ReadRegister1(Instruction[25:21]),
        .ReadRegister2(Instruction[20:16]),
        .WriteRegister(WriteRegister),
        .WriteData(WriteData),
        .RegWrite(RegWrite),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2),    
    );

    assign SignExtend = { {16{Instruction[15]}}, Instruction[15:0] };

    assign ALUInput2 = ALUSrc ? SignExtend : ReadData2;

    ALU alu (
        .A(ReadData1),
        .B(ALUInput2),
        .ALUOperation(ALUControl),
        .ALUResult(ALUResult),
        .Zero(Zero),
    );

    // A ordem importa ?
    assign WriteRegister = RegDst ? Instruction[15:11] : Instruction[20:16];

    assign WriteData = MemtoReg ? MemData : ALUResult;

    ALUControl alu_control (
        .ALUOp(ALUOp),
        .Funct(Instruction[5:0]),
        .ALUControl(ALUControl),
    );

endmodule