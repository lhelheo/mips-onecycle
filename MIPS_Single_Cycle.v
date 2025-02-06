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

module ControlUnit (
    input wire [5:0] Opcode,
    output reg RegDst, 
    output reg ALUSrc,
    output reg MemtoReg,
    output reg RegWrite,
    output reg MemRead,
    output reg MemWrite,
    output reg Branch,
    output reg [1:0] ALUOp,
    output reg Jump
);

    always @(*) begin
      case (Opcode)
        6'b000000: begin // R-Type
            RegDst = 1;
            ALUSrc = 0;
            MemtoReg = 0;
            RegWrite = 1;
            MemRead = 0;
            MemWrite = 0;
            Branch = 0;
            ALUOp = 2'b10;
            Jump = 0;
        end
        6'b100011: begin // lw
            RegDst = 0;
            ALUSrc = 1;
            MemtoReg = 1;
            RegWrite = 1;
            MemRead = 1;
            MemWrite = 0;
            Branch = 0;
            ALUOp = 2'b00;
            Jump = 0;
        end
        6'b101011: begin // sw
            RegDst = 0;
            ALUSrc = 1;
            MemtoReg = 0;
            RegWrite = 0;
            MemRead = 0;
            MemWrite = 1;
            Branch = 0;
            ALUOp = 2'b00;
            Jump = 0;
        end
        6'b000100: begin // beq
            RegDst = 0;
            ALUSrc = 0;
            MemtoReg = 0;
            RegWrite = 0;
            MemRead = 0;
            MemWrite = 0;
            Branch = 1;
            ALUOp = 2'b01;
            Jump = 0;
        end
        6'b000010: begin // jump
            RegDst = 0;
            ALUSrc = 0;
            MemtoReg = 0;
            RegWrite = 0;
            MemRead = 0;
            MemWrite = 0;
            Branch = 0;
            ALUOp = 2'b00;
            Jump = 1;
        end
        default: begin // Instrução inválida
            RegDst = 0;
            ALUSrc = 0;
            MemtoReg = 0;
            RegWrite = 0;
            MemRead = 0;
            MemWrite = 0;
            Branch = 0;
            ALUOp = 2'b00;
            Jump = 0;
        end
    endcase
end

endmodule

module ALUControl (
    input wire [1:0] ALUOp,
    input wire [5:0] Funct,
    output reg [3:0] ALUOperation
);

    always @(*) begin
        case (ALUOp)
            2'b00: ALUOperation = 4'b0010; // soma lw/sw
            2'b01: ALUOperation = 4'b0110; // sub beq
            2'b10: begin
                case (Funct)
                    6'b100000: ALUOperation = 4'b0010; // add
                    6'b100010: ALUOperation = 4'b0110; // sub
                    6'b100100: ALUOperation = 4'b0000; // and
                    6'b100101: ALUOperation = 4'b0001; // or
                    6'b101010: ALUOperation = 4'b0111; // slt
                    default: ALUOperation = 4'b0000; // Instrução inválida
                endcase
            end
            default: ALUOperation = 4'b0000; // Instrução inválida
        endcase
    end

endmodule