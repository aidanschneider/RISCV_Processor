// based on op code, concactinate/generate
// 32-bit output
// module immed# (
//     input  logic [31:0] inst,     // The full 32-bit raw instruction
//     output logic [31:0] imm_out   // The sign-extended 32-bit immediate output
// );

module immGen (
    input logic [2:0]  ImmSrc,
    input logic [31:0] instruction,
    output logic [31:0] ImmExt
);

always_comb begin

    case(ImmSrc)
        // I-type: ADDI, LW, JALR, etc.
        3'b000: begin ImmExt = {{20{instruction[31]}},instruction[31:20]}; end
        // S-type: SW, SH, SB
        3'b001: begin ImmExt = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};end
        // B-type: BEQ, BNE, BLT, BGE, etc.
        3'b010: begin ImmExt = {{19{instruction[31]}},instruction[31],instruction[7],instruction[30:25],instruction[11:8],1'b0}; end
        // U-type: LUI, AUIPC
        3'b011: begin ImmExt = {instruction[31:12], 12'b0};end
        // J-type: JAL
        3'b100: begin ImmExt = {{11{instruction[31]}},instruction[31],instruction[19:12],instruction[20],instruction[30:21],1'b0};end
        default: ImmExt = 32'b0;
    endcase

end

endmodule