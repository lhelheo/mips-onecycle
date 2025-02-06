`timescale 1ns
`include "ALU.v"
`include "Registradores.v"
`include "ControlUnit.v"
`include "ALUControl.v"
`include "MIPS_Single_Cycle.v"

module Simulacao;
    reg clk;
    reg reset;

    MIPS_Single_Cycle mips (
        .clk(clk),
        .reset(reset)
    );

    integer i;

    initial begin
        $dumpfile("mips_single_cycle.vcd");
        $dumpvars(0, Simulacao);

        clk = 0;
        reset = 1;
        #10;
        reset = 0;

        for (i = 0; i < 50; i = i + 1) begin
            #10;
            clk = ~clk;
        end

        $finish;
    end

    initial begin
        $monitor("Time: %0d, PC: %h, Instruction: %h, ALUResult: %h, Zero: %b",
            $time, mips.PC, mips.Instruction, mips.ALUResult, mips.Zero);
    end
endmodule