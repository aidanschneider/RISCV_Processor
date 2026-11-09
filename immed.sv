// based on op code, concactinate/generate
// 32-bit output
// module immed# (
//     input  logic [31:0] inst,     // The full 32-bit raw instruction
//     output logic [31:0] imm_out   // The sign-extended 32-bit immediate output
// );

module immGen(Opcode, instruction, immExt);

input [6:0] Opcode;
input [31:0] instruction;
output [31:0] ImmExt;

always@(*)
begin
    case(Opcode)
    // lhs from immed input bits, rhs from immed instruction type
    7'b000011 : ImmExt = {{20{instruction[31]}}, instruction[31:20]} // I type make 20 copies of MSB value  of instruction, then put it in 31:20 of instruction
    7'b0100011 : ImmExt = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // S type
    7'b1100011 ImmExt = {{19{instruction[31]}}, instruction[31], instruction[30:25], instruction[11:8],1'b0} // sb-type
    //might be missing more things? ill check later but this was what video had from the part i watched
    endcase

end

endmodule