`timescale 1ns/1ps

module testbench();

    logic clk = 0;
    logic reset = 1;

    logic LED, RGB_R, RGB_G, RGB_B;

    // Instantiate processor
    top dut (
        .clk(clk),
        .LED(LED),
        .RGB_R(RGB_R),
        .RGB_G(RGB_G),
        .RGB_B(RGB_B)
    );

    always #5 clk = ~clk;

    // Initialize and run
    initial begin
        $dumpfile("riscvtest.vcd");
        $dumpvars(0, testbench);

        // Reset processor
        reset = 1;
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Timeout
        repeat (10000) @(posedge clk);

        $fatal(1, "Simulation timed out!");
    end

    // Check processor results
    always @(negedge clk) begin

        if (dut.MemWrite === 1'b1) begin

            // FAIL signature
            if (dut.DataAdr === 32'd104) begin
                $fatal(1, "Simulation FAILED! WriteData = %h",
                       dut.WriteData);
            end

            // PASS signature
            if (dut.DataAdr === 32'd100) begin

                if (dut.WriteData === 32'd25) begin
                    $display("     RISC-V SIMULATION PASSED");
                    $finish;
                end else begin
                    $fatal(1, "Incorrect PASS signature: %h",
                           dut.WriteData);
                end

            end
        end
    end

endmodule