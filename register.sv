// RV32I register module

/*
Implement the register file. Creates a dedicated memory block for the 32 
registers and read/write commands.

Update the output value signals based on the data stored at the adresses 
specified by the inputs signals. Follow the read before write pattern, enforced by the write enable signal from the controller. Include proper handling for read/writes to the zero register (r0).
*/

module register #(
    parameter CLK_FREQ = 12000000
)(
    input logic     clk, 
    input logic     register_wren, // write-enable signal

    // From the instruction register:
    input logic     [4:0]rs1, // Source register 1
    input logic     [4:0]rs2, // Source register 2
    input logic     [4:0]rd, // Desitination register

    input logic     [31:0]rdv, // Destination register value
    output logic    [31:0]rs1v, // Source register 1 value
    output logic    [31:0]rs2v // Source register 2 value
);
    // RISC-V defines 32 registers, each of which are 32 bits wide
    logic [31:0] register_memory [31:0];

    // Set all registers to zero initially
    initial begin
        for (int i = 0; i < 32; i++) begin
            register_memory[i] = 32'b0;
        end
    end

    // Combinatorically determine and output the value of each source register. 
    // Explicitly read out 0 from the zero register.
    assign rs1v = (rs1 == 5'b0) ? 5'b0 : register_memory[rs1];
    assign rs1v = (rs2 == 5'b0) ? 5'b0 : register_memory[rs1];

    // On each rising clock edge, update the value of the destination register 
    // (if write is enabled)
    always_ff @(posedge clk) begin
        // Only write if the write enable signal is present and the destination register is not the zero register.
        if (register_wren == 1 && (rd != 5'b0)) begin
            register_memory[rd] <= rdv;
        end
    end

endmodule