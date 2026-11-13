// module ALU(
//     input  wire [1:0] alu_op,      // From Main Control Unit
//     input  wire [2:0] funct3,      // From instruction[14:12]
//     input  wire       funct7_b30,  // From instruction[30] (Only need bit 30!)
//     output reg  [3:0] alu_control  // Output signal directly to ALU
// );
// endmodule
// determine operator from prog from funct3 and funct7
// funct 3 is 3 bits Narrows down the category to a specific type of operation 
// funct 7 is 7 bits Provides the final modification when funct3 isn't enough to distinguish two similar commands (e.g., "Perform an ADD" vs. "Perform a SUB")

// huge switch case in always block

module ALU_unit(
    input [31:0] A,
    input [31:0] B,
    input [3:0] control_in,
    output logic [31:0] ALU_Result,
    output logic zero);

    always_comb begin

        // based on ALU control lines to function table
        // I SAW DIFFERENT THINGS IN DIFFERENT PLACES SO WE HAVE TO MAKE SURE TO BE CONSISTENT
        case(control_in)
            4'b0000: ALU_Result = A + B; // ADD
            4'b0001: ALU_Result = A - B; // SUB
            4'b0010: ALU_Result = A & B; // AND
            4'b0011: ALU_Result = A | B; // OR
            4'b0100: ALU_Result = A ^ B; // XOR
            4'b0101: ALU_Result = A << B[4:0]; // SLL
            4'b0110: ALU_Result = A >> B[4:0]; // SRL
            4'b0111: ALU_Result = $signed(A) >>> B[4:0]; // SRA
            4'b1000: ALU_Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; // SLT
            4'b1001: ALU_Result = (A < B) ? 32'd1 : 32'd0; // SLTU
            default: ALU_Result = 32'd0;
        endcase

        // maybe assign lt_signed and lt_unsigned

    end
    assign zero = (ALU_Result == 32'd0);

endmodule


module ALU_Control (
    input  logic [1:0] ALUOp,
    input  logic       op5,
    input  logic       funct75,
    input  logic [2:0] funct3,
    output logic [3:0] control_out
);

    always_comb begin
        control_out = 4'b0000; // Default: ADD
        case (ALUOp)
            // Address calculations and PC + 4
            2'b00: control_out = 4'b0000; // ADD
            // Branch comparisons
            2'b01: begin
                case (funct3)
                    3'b000: control_out = 4'b0001; // BEQ: SUB
                    3'b001: control_out = 4'b0001; // BNE: SUB
                    3'b100: control_out = 4'b1000; // BLT: SLT
                    3'b101: control_out = 4'b1000; // BGE: SLT
                    3'b110: control_out = 4'b1001; // BLTU: SLTU
                    3'b111: control_out = 4'b1001; // BGEU: SLTU
                    default: control_out = 4'b0000;
                endcase
            end

            // Decode R-type and I-type ALU instructions
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        // SUB only for register-register SUB.
                        if (op5 && funct75)
                            control_out = 4'b0001;
                        else
                            control_out = 4'b0000;
                    end

                    3'b001: control_out = 4'b0101; // SLL
                    3'b010: control_out = 4'b1000; // SLT
                    3'b011: control_out = 4'b1001; // SLTU
                    3'b100: control_out = 4'b0100; // XOR

                    3'b101: begin
                        if (funct75)
                            control_out = 4'b0111; // SRA
                        else
                            control_out = 4'b0110; // SRL
                    end

                    3'b110: control_out = 4'b0011; // OR
                    3'b111: control_out = 4'b0010; // AND

                    default: control_out = 4'b0000;
                endcase
            end

            default: control_out = 4'b0000;

        endcase
    end

endmodule