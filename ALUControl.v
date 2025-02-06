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