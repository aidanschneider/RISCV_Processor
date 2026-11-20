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
    Logic Signals
    */

    // Memory module
    logic [31:0] dmem_data_out;
    logic [31:0] imem_data_out;
    logic reset; // active low
    logic led;
    logic red;
    logic green;
    logic blue;

    // Controller module
    logic zero = 1'b0;
    logic pcwrite = 1'b0;
    logic adrsrc;
    logic memwrite = 1'b0;
    logic irwrite = 1'b0;
    logic [1:0] resultsrc;
    logic [1:0] alusrca;
    logic [1:0] alusrcb;
    logic [3:0] alucontrol;
    logic regwrite = 1'b0;
    logic [2:0] immsrc;

    // Register file module
    logic [31:0] rs1v;
    logic [31:0] rs2v;

    // ALU module
    logic [31:0] SrcA, SrcB;
    logic [31:0] ALU_Result;

    // Immediate generator module
    logic [31:0] ImmExt;

    // Instruction fields
    logic [31:0] instruction;
    logic [6:0] op;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic op5; // op code bit 5
    logic funct7b5; // func7 bit 5
    logic [2:0] funct3;

    // registers + muxes
    logic [31:0] pc = 32'h00001000;
    logic [31:0] old_pc;
    logic [31:0] ALU_Out;
    logic [31:0] A;
    logic [31:0] B;
    logic [31:0] result;
    logic [31:0] data;
    logic [31:0] adr;

    // RGB Cycle
    // logic [3:0] state = INIT;
    // logic [21:0] count = 22'd0;

    /*
    Instantiate Modules
    */

    memory #(
        .IMEM_INIT_FILE_PREFIX  ("rv32i_test")
    ) u1 (
        .clk            (clk), 
        .funct3         (funct3), 
        .dmem_wren      (memwrite), 
        .dmem_address   (adr), 
        .dmem_data_in   (B), 
        .imem_address   (pc), 
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
     .clk (clk),
     .register_wren (regwrite),
     .rs1 (rs1),
     .rs2 (rs2),
     .rd (rd),
     .rdv (result),
     .rs1v (rs1v),
     .rs2v (rs2v) );
     
    // alu

    ALU_unit #(

    ) u3 (
    .A (SrcA),
    .B (SrcB),
    .control_in (alucontrol),
    .ALU_Result (ALU_Result),
    .zero (zero)
    );

    // immediate generator

    immGen #(

    ) u5 (
    .ImmSrc (immsrc),
    .instruction (instruction),
    .ImmExt (ImmExt)
    );

    // controller

    controller #(

    ) u6 (
    .clk (clk),
    .reset (reset),
    .op (op),
    .funct3 (funct3),
    .funct7b5 (funct7b5),
    .zero (zero),
    // outputs
    .pcwrite (pcwrite),
    .adrsrc (adrsrc),
    .memwrite (memwrite),
    .irwrite (irwrite),
    .resultsrc (resultsrc),
    .alusrca (alusrca),
    .alusrcb (alusrcb),
    .alucontrol (alucontrol),
    .regwrite (regwrite),
    .immsrc (immsrc)

    );

    /*
    Parse instruction
    */
    assign op = instruction[6:0];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign funct7b5 = instruction[30];
    assign op5 = instruction[5];


    /*
    Create registers
    */
    always_ff @(posedge clk) begin
        // Program counter register
        if (!reset) begin
            pc <= 32'h00001000;
        end else if (pcwrite) begin
            pc <= result;
        end
        // Instruction register
        if (irwrite) begin
            old_pc <= pc;
            instruction <= imem_data_out;
        end
        // Data register
        data <= dmem_data_out; // JK: not sure if this correct
        // Source values register
        A <= rs1v;
        B <= rs2v;
        // ALU output register
        ALU_Out <= ALU_Result;

    end


    /*
    Wire multiplexers
    */
    always_comb begin
        // Set defaults (to be overrided by case statements)
        adr = pc;
        SrcA = pc;
        SrcB = B;
        result = ALU_Out;

        // Memory address mux
        case(adrsrc)
            1'b0: adr = pc;
            1'b1: adr = result;
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
            2'b11: result = ImmExt;
        endcase
    end

    /*
    Main Loop: Cycle RGB LED
    */
    // always_ff @(negedge clk) begin
    //     case (state)
    //         INIT: begin
    //             dmem_address <= 32'hFFFFFFFC;
    //             dmem_data_in <= 32'hFFFF0000;
    //             dmem_wren <= 1'b1;
    //             count <= STATE_DWELL_CYCLES;
    //             state <= RED;
    //         end
    //         RED: begin
    //             if (count > 22'd0) begin
    //                 count <= count - 1;
    //             end
    //             else begin
    //                 dmem_data_in <= 32'hFFFFFF00;
    //                 count <= STATE_DWELL_CYCLES;
    //                 state <= YELLOW;
    //             end
    //         end
    //         YELLOW: begin
    //             if (count > 22'd0) begin
    //                 count <= count - 1;
    //             end
    //             else begin
    //                 dmem_data_in <= 32'hFF00FF00;
    //                 count <= STATE_DWELL_CYCLES;
    //                 state <= GREEN;
    //             end
    //         end
    //         GREEN: begin
    //             if (count > 22'd0) begin
    //                 count <= count - 1;
    //             end
    //             else begin
    //                 dmem_data_in <= 32'h0000FFFF;
    //                 count <= STATE_DWELL_CYCLES;
    //                 state <= CYAN;
    //             end
    //         end
    //         CYAN: begin
    //             if (count > 22'd0) begin
    //                 count <= count - 1;
    //             end
    //             else begin
    //                 dmem_data_in <= 32'h000000FF;
    //                 count <= STATE_DWELL_CYCLES;
    //                 state <= BLUE;
    //             end
    //         end
    //         BLUE: begin
    //             if (count > 22'd0) begin
    //                 count <= count - 1;
    //             end
    //             else begin
    //                 dmem_data_in <= 32'h00FF00FF;
    //                 count <= STATE_DWELL_CYCLES;
    //                 state <= MAGENTA;
    //             end
    //         end
    //         MAGENTA: begin
    //             if (count > 22'd0) begin
    //                 count <= count - 1;
    //             end
    //             else begin
    //                 dmem_data_in <= 32'hFFFF0000;
    //                 count <= STATE_DWELL_CYCLES;
    //                 state <= RED;
    //             end
    //         end
    //     endcase
    // end


    /*
    Connect memory-mapped peripherals to hardware
    */
    assign LED = ~led;
    assign RGB_R = ~red;
    assign RGB_G = ~green;
    assign RGB_B = ~blue;

endmodule