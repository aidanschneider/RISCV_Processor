`timescale 10ns/10ns
`include "top.sv"

module testbench();
    logic clk = 0;
    logic LED, RGB_R, RGB_G, RGB_B
    // instantiate device to be tested
    top u0 (
        .clk            (clk), 
        .LED            (LED), 
        .RGB_R          (RGB_R), 
        .RGB_G          (RGB_G), 
        .RGB_B          (RGB_B)
    );

    // Generates the simulation to check signals
    initial begin
        $dumpfile("proj1.vcd");
        $dumpvars(0, tb_top);
        #100000;
        $finish;
    end

    // check results
    always @(negedge clk) begin
            if(MemWrite) begin
                if(DataAdr === 100 & WriteData === 25) begin
                    $display("Simulation succeeded");
                    $stop;
                end else if (DataAdr !== 96) begin
                    $display("Simulation failed");
                    $stop;
                end
            end
        end

    always begin
        #4
        clk = ~clk;
    end
    // I think the code above is more correct
    // initialize test
    // initial
    //     begin
    //         reset <= 1; # 22; reset <= 0;
    // end


    /*
    Add other smaller test cases
    xor, sll, srl, sra, sltu, 
    immediate logic/shifts (xori, ori, andi, slli, srli, srai, slti, sltiu), 
    other branches (bne, blt, bge, bltu, bgeu), 
    upper immediates (lui, auipc), 
    indirect jumps (jalr),
    byte/halfword memory accesses (lb, lh, lbu, lhu, sb, sh).
    */
endmodule