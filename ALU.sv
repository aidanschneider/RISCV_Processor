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
    input [3:0] Control_in,
    output logic [31:0] ALU_Result,
    output logic zero);

    always_comb begin

        // based on ALU control lines to function table
        // I SAW DIFFERENT THINGS IN DIFFERENT PLACES SO WE HAVE TO MAKE SURE TO BE CONSISTENT
        case(Control_in)
            4'b0000: ALUResult = SrcA + SrcB; // ADD
            4'b0001: ALUResult = SrcA - SrcB; // SUB
            4'b0010: ALUResult = SrcA & SrcB; // AND
            4'b0011: ALUResult = SrcA | SrcB; // OR
            4'b0100: ALUResult = SrcA ^ SrcB; // XOR
            4'b0101: ALUResult = SrcA << SrcB[4:0]; // SLL
            4'b0110: ALUResult = SrcA >> SrcB[4:0]; // SRL
            4'b0111: ALUResult = $signed(SrcA) >>> SrcB[4:0]; // SRA
            4'b1000: ALUResult = lt_signed ? 32'd1 : 32'd0; // SLT
            4'b1001: ALUResult = lt_unsigned ? 32'd1 : 32'd0; // SLTU
            default: ALUResult = 32'd0;
        endcase

        assign zero = (ALU_Result == 32'd0);
        // maybe assign lt_signed and lt_unsigned

    end

endmodule

module ALU_Control (
    input  logic [1:0] ALUOp,
    input  logic funct7,
    input  logic [2:0] funct3,
    output logic [3:0] Control_out
);

    always_comb begin

    case({ALUOp, funct7, funct3})
    6'b00_0_000: Control_out = 4'b0010;
    6'b01_0_000: Control_out = 4'b0110;
    6'b10_0_000: Control_out = 4'b0010;
    6'b10_1_000: Control_out = 4'b0110;
    6'b10_0_111: Control_out = 4'b0000;
    6'b10_0_110: Control_out = 4'b0001;
    default: Control_out = 4'b0000;
    endcase
end
endmodule

//dunno if this was part of my code, but did it anyways
module Data_Memory (
    input  logic        clk,
    input  logic        reset,
    input  logic        MemWrite,
    input  logic        MemRead,
    input  logic [31:0] read_address,
    input  logic [31:0] Write_data,
    output logic [31:0] Memdata_out
);


integer k;
logic [31:0] D_Memory[63:0];

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
        for(k=0; k<64; k=k+1)begin
            D_Memory[k] <= 32'b00;
        end

    end
        else if (MemWrite) begin
            D_Memory[read_address[5:0]] <= Write_data; // todo maybe this should be [7:2]
        end
end
    always_comb begin
        assign Memdata_out = (MemRead) ? D_Memory[read_address[5:0]] : 32'b0;
    end


endmodule 