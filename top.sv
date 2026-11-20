`include "memory.sv"
`include "register.sv"
`include "ALU.sv"
`include "immGen.sv"
`include "controller.sv"

module top (
    input logic clk, 
    output logic LED, 
    output logic RGB_R, 
    output logic RGB_G, 
    output logic RGB_B
);
    /*
    Local Parameters
    */
    
    // Create a numeric code for each color
    localparam [3:0] INIT       = 4'd0;
    localparam [3:0] RED        = 4'd1;
    localparam [3:0] YELLOW     = 4'd2;
    localparam [3:0] GREEN      = 4'd3;
    localparam [3:0] CYAN       = 4'd4;
    localparam [3:0] BLUE       = 4'd5;
    localparam [3:0] MAGENTA    = 4'd6;

    // Number of clock cycles to remain in each color
    localparam [21:0] STATE_DWELL_CYCLES = 22'd3000000;
    
    /*
    Module Logic Signals
    */

    // Memory module
    logic [2:0] funct3 = 3'b010;
    logic dmem_wren = 1'b0;
    logic [31:0] dmem_address = 31'd0;
    logic [31:0] dmem_data_in = 31'd0;
    logic [31:0] dmem_data_out;
    logic [31:0] imem_address = 31'h1000;
    logic [31:0] imem_data_out;
    logic reset;
    logic led;
    logic red;
    logic green;
    logic blue;
    logic memory_reset

    /*
    Other Logic Signals
    */
    //instruction fields
    logic [31:0] instruction
    logic[6:0] op;
    logic[4:0] rs1;
    logic[4:0] rs2;
    logic[4:0] rd;

    logic [31:0] A,
    logic [31:0] B,
    logic [3:0] control_in,

    logic [1:0] ALUOp,
    logic op5,
    logic funct75,
    logic [2:0] funct3,


    logic [3:0] state = INIT;
    logic [21:0] count = 22'd0;

    logic reset,
    logic zero,

    logic [31:0] ALU_Result;

    //someone needs to define pc counter, old pc
    /*
    Instantiate Modules
    */

    memory #(
        .IMEM_INIT_FILE_PREFIX  ("rv32i_test")
    ) u1 (
        .clk            (clk), 
        .funct3         (funct3), 
        .dmem_wren      (dmem_wren), 
        .dmem_address   (dmem_address), 
        .dmem_data_in   (dmem_data_in), 
        .imem_address   (imem_address), 
        .imem_data_out  (imem_data_out), 
        .dmem_data_out  (dmem_data_out), 
        .reset          (reset), 
        .led            (led), 
        .red            (red), 
        .green          (green), 
        .blue           (blue)
    );

    //register file
    register #(

    ) u2 (
     .clk, (clk),
     .register_wren (register_wren),
     .rs1 (rs1),
     .rs2 (rs2),
     .rd (rd),
     .rdv (rdv),
     .rs1v (rs1v),
     .rs2v (rs2v) );
     
    // alu + immgen

    // controller



    controller #(

    ) u6 (
    .clk (clk),
    .reset (reset),
    .op (op),
    .funct3 (funct3),
    .funct7b5 (funct75), // assuming 7b5 is same as 75
    .zero (zero),
    // outputs
    .pcwrite (pcwrite),
    .adrsrc (adrsrc),
    .memwrite (memwrite),
    .irwrite (irwrite),
    .resultsrc, (resultsrc),
    .alusrca, (alusrca),
    .alusrcb, (alusrcb),
    .alucontrol, (alucontrol),
    .regwrite, (regwrite),
    .immsrc, (immsrc)

    );
    ALU_unit #(

    ) u3 (
    .A (SrcA),
    .B (SrcB),
    .control_in (alucontrol),
    .ALU_Result (ALU_Result),
    .zero (zero)
    );



    ALU_Control #(

    ) u4 (
    .ALUOp (ALUOp),
    .op5 (op5),
    .funct75 (funct75),
    .funct3 (funct3),
    .control_out (control_out)
    );

    immGen #(

    ) u5 (
    .ImmSrc (ImmSrc),
    .instruction (instruction).
    .ImmExt (ImmExt),
    );

    /*
    Create registers
    */
    always_ff @(posedge clk) begin
        // Program counter register
        if (pcwrite) begin
            pc = result;
        end
        // Instruction register
        if (irwrite) begin
            old_pc = pc;
            instruction = imem_data_out;
        end
        // Data register
        data = dmem_data_out; // JK: not sure if this correct
        // Source values register
        A = rs1v;
        B = rs2v;
        // ALU output register
        ALU_Out = ALU_Result;

    end


    /*
    Wire multiplexers
    */
    always_comb begin
        // Memory address mux
        case(adrsrc)
            1'b0: adr = pc;
            1'b1: adr = ALU_Result;
        endcase

        // ALU Operand A mux
        case(alusrca)
            2'b00: SrcA = pc;
            2'b01: SrcA = old_pc;
            2'b10: SrcA = A;
        endcase

        // ALU Operand B mux
        case(alusrcb)
            2'b00: SrcB = B;
            2'b01: SrcB = ImmExt;
            2'b10: SrcB = 32'd4;
        endcase

        // Result mux
        case(resultsrc)
            2'b00: result = ALU_Out;
            2'b01: result = data;
            2'b10: result = ALU_Result;
        endcase
    end

    /*
    Main Loop: Cycle RGB LED
    */
    always_ff @(negedge clk) begin
        case (state)
            INIT: begin
                dmem_address <= 32'hFFFFFFFC;
                dmem_data_in <= 32'hFFFF0000;
                dmem_wren <= 1'b1;
                count <= STATE_DWELL_CYCLES;
                state <= RED;
            end
            RED: begin
                if (count > 22'd0) begin
                    count <= count - 1;
                end
                else begin
                    dmem_data_in <= 32'hFFFFFF00;
                    count <= STATE_DWELL_CYCLES;
                    state <= YELLOW;
                end
            end
            YELLOW: begin
                if (count > 22'd0) begin
                    count <= count - 1;
                end
                else begin
                    dmem_data_in <= 32'hFF00FF00;
                    count <= STATE_DWELL_CYCLES;
                    state <= GREEN;
                end
            end
            GREEN: begin
                if (count > 22'd0) begin
                    count <= count - 1;
                end
                else begin
                    dmem_data_in <= 32'h0000FFFF;
                    count <= STATE_DWELL_CYCLES;
                    state <= CYAN;
                end
            end
            CYAN: begin
                if (count > 22'd0) begin
                    count <= count - 1;
                end
                else begin
                    dmem_data_in <= 32'h000000FF;
                    count <= STATE_DWELL_CYCLES;
                    state <= BLUE;
                end
            end
            BLUE: begin
                if (count > 22'd0) begin
                    count <= count - 1;
                end
                else begin
                    dmem_data_in <= 32'h00FF00FF;
                    count <= STATE_DWELL_CYCLES;
                    state <= MAGENTA;
                end
            end
            MAGENTA: begin
                if (count > 22'd0) begin
                    count <= count - 1;
                end
                else begin
                    dmem_data_in <= 32'hFFFF0000;
                    count <= STATE_DWELL_CYCLES;
                    state <= RED;
                end
            end
        endcase
    end


    /*
    Connect memory-mapped peripherals to hardware
    */
    assign LED = ~led;
    assign RGB_R = ~red;
    assign RGB_G = ~green;
    assign RGB_B = ~blue;

endmodule