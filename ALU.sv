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

module ALU_unit(A, B, Control_in, ALU_result, zero);

input [31:0] A, B
input [3:0] Control_in;
output reg zero;
output reg [31:0] ALU_Result

always @(Control_in, or A or B)
begin
    // based on ALU control lines to function table
    case(Control_in)
    4'b0000: begin zero <= 0; ALU_Result <= A & B; end
    4'b0001: begin zero<=0; ALU_Result <= A | B; end
    4'b0010: begin zero<=0; ALU_Result <= A + B; end
    4'b0011: begin if(A==B) zero<=1; else zero<= 0; ALU_Result <= A - B; end
    endcase

end

endmodule

module ALU_Control(ALUOp, funct7, funct3, Control_out);

input funct7;
input[2:0] funct3;
output reg [3:0] Control_out;

always @(*)
begin
    case({ALUOp, funct7, funct3})
    6'b00_0_000: Control_out <= 4'b0010;
    //TODO REST OF THEM
end
endmodule