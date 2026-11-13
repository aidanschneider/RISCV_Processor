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

    //register
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
    .resultssrc, (resultsrc),
    .alusrca, (alusrca),
    .alusrcb, (alusrcb),
    .alucontrol, (alucontrol),
    .regwrite, (regwrite),

    );
    ALU_unit #(

    ) u3 (
    .A (A),
    .B (B),
    .control_in (control_in),
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
    Wire multiplexers
    */
    always_comb begin
        // Program counter mux
        case(pc_sel)
            1'b0: pc = pc_addr_output;
            1'b1: pc = ALU_Result;
        endcase

        // ALU Operand 1 mux
        case(op1_sel)
            1'b0: A = rs1v;
            1'b1: A = pc;
        endcase

        // ALU Operand 2 mux
        case(op2_sel)
            1'b0: B = rs2v;
            1'b1: B = ImmExt;
        endcase

        // Destination register mux
        case(rd_sel)
            2'b00: rdv = ALU_Result;
            2'b01: rdv = dmem_data_out;
            2'b10: rdv = pc_addr_output;
            2'b11: rdv = ImmExt;
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