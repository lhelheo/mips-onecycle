module MIPS_Single_Cycle(
    input wire clk,
    input wire reset
);

    // Sinais de controle
    wire RegDst, ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch, Jump;
    wire [1:0] ALUOp;

    // Sinais de dados
    reg [31:0] PC; // Declarado como reg
    wire [31:0] NextPC, Instruction, ReadData1, ReadData2, ALUResult, WriteData, SignExtend, ALUInput2, MemData;
    wire [4:0] WriteRegister;
    wire Zero, PCSrc;

    // Memória de instruções
    reg [31:0] InstructionMemory [0:1023]; // 1KB de memória de instruções
    initial $readmemh("program.hex", InstructionMemory); // Carrega o programa

    // Memória de dados
    reg [31:0] DataMemory [0:1023]; // 1KB de memória de dados
    initial $readmemh("data.hex", DataMemory); // Carrega dados iniciais

    // Program Counter
    always @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 32'b0; // Reseta o PC
        else
            PC <= NextPC; // Atualiza o PC
    end

    // Busca da instrução
    assign Instruction = InstructionMemory[PC >> 2]; // PC é byte address, memória é word address

    // Unidade de controle
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

    // Banco de registradores
    Registradores regfile (
        .ReadRegister1(Instruction[25:21]),
        .ReadRegister2(Instruction[20:16]),
        .WriteRegister(WriteRegister),
        .WriteData(WriteData),
        .RegWrite(RegWrite),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );

    // Extensão de sinal
    assign SignExtend = { {16{Instruction[15]}}, Instruction[15:0] };

    // Multiplexador ALUSrc
    assign ALUInput2 = ALUSrc ? SignExtend : ReadData2;

    // ALU
    ALU alu (
        .A(ReadData1),
        .B(ALUInput2),
        .ALUOperation(ALUControl),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );

    // Multiplexador RegDst
    assign WriteRegister = RegDst ? Instruction[15:11] : Instruction[20:16];

    // Memória de dados
    assign MemData = DataMemory[ALUResult >> 2]; // Leitura da memória de dados
    always @(posedge clk) begin
        if (MemWrite)
            DataMemory[ALUResult >> 2] <= ReadData2; // Escrita na memória de dados
    end

    // Multiplexador MemtoReg
    assign WriteData = MemtoReg ? MemData : ALUResult;

    // Unidade de controle da ALU
    ALUControl alu_control (
        .ALUOp(ALUOp),
        .Funct(Instruction[5:0]),
        .ALUOperation(ALUControl)
    );

    // Lógica de Branch
    assign PCSrc = Branch & Zero;
    assign NextPC = Jump ? {PC[31:28], Instruction[25:0], 2'b00} : // Jump
                    PCSrc ? PC + 4 + (SignExtend << 2) : // Branch
                    PC + 4; // Próxima instrução

endmodule