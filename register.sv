// RV32I register module

/*
Implement the register file. Creates a dedicated memory block for the 32 
registers and read/write commands.

Update the output value signals based on the data stored at the adresses 
specified by the inputs signals. Follow the read before write pattern. Include 
proper handling for read/writes to the zero register (r0).
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
    output logic    [31:0]rs2v, // Source register 2 value
);

    // Module contents here

endmodule