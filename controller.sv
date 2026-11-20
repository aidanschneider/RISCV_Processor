// note, this controller module is based off the multi-cycle controller architecture provided 
// in the Harris and Harris textbook

module controller (
    input  logic       clk,
    input  logic       reset,
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    input  logic       zero,

    output logic       pcwrite,
    output logic       adrsrc,
    output logic       memwrite,
    output logic       irwrite,
    output logic [1:0] resultsrc,
    output logic [1:0] alusrca,
    output logic [1:0] alusrcb,
    output logic [3:0] alucontrol,
    output logic       regwrite,
    output logic [2:0] immsrc
    );

logic branch, pcupdate;
logic[1:0] aluop;

// defining enums for each state of the controller FSM
typedef enum logic[3:0] {FETCH, DECODE, EXECUTER, ALUWB, MEMADR, EXECUTEI, JAL, BEQ, MEMREAD, MEMWRITE, MEMWB, LUI} statetype;
// declaring statetypes to keep track of current and next state
statetype state, nextstate;


// always block setting current state
always_ff @(posedge clk, negedge reset) begin
    // fetch is first state in FSM, so if reset go back to beginning
    if (!reset) state <= FETCH;
    // otherwise just proceed to next state
    else state <= nextstate;
end

// logic for determining what the next state is
always_comb begin
    case(state)
        // next step after fetching instruction is always decoding
        FETCH: nextstate = DECODE;
        // next step after decoding determined by opcode
        DECODE: 
            case(op) 
                // R-type instruction
                7'b0110011: nextstate = EXECUTER;
                // TODO: IMPLEMENT OTHER INSTRUCTION TYPES
                7'b0000011: nextstate = MEMADR;
                7'b0100011: nextstate = MEMADR;
                7'b0010011: nextstate = EXECUTEI;
                7'b1101111: nextstate = JAL;
                7'b1100011: nextstate = BEQ;

                // for auipc
                7'b0010111: nextstate = ALUWB;

                //for jalr, DECODE case
                7'b1100111: nextstate = MEMADR;

                // for lui
                7'b0110111: nextstate = LUI;

                // default to fetch
                default: nextstate = FETCH;
            endcase
        
        // next step after MEMADR determined by opcode (lw or sw)
        MEMADR:
            case(op) 
                7'b0000011: nextstate = MEMREAD;
                7'b0100011: nextstate = MEMWRITE;

                // for jalr, MEMADR case
                7'b1100111: nextstate = JAL;

                default: nextstate = FETCH;
            endcase 
        
        // next step after MEMREAD is MEMWB
        MEMREAD: nextstate = MEMWB;
        // next step from EXECUTER, EXECUTEI, and EXECUTER is ALUWB
        EXECUTER: nextstate = ALUWB;
        EXECUTEI: nextstate = ALUWB;
        JAL:      nextstate = ALUWB;
        // next step from ALUWB, BEQ, MEMWRITE, LUI, and MEMWB is FETCH
        ALUWB: nextstate = FETCH;
        MEMWRITE: nextstate = FETCH;
        MEMWB: nextstate = FETCH;
        BEQ: nextstate = FETCH;
        LUI: nextstate = FETCH;
        // default next step is FETCH
        default: nextstate = FETCH;

    
    endcase 
end

// logic for determining controller signal outputs
// signal values derived from Figure 7.45 in textbook
always_comb begin
    // default, all signals off
    adrsrc = 0;
    irwrite = 0;
    memwrite = 0;
    regwrite = 0;
    pcupdate = 0;
    branch = 0;
    alusrca = 2'b00;
    alusrcb = 2'b00;
    aluop = 2'b00;
    resultsrc = 2'b00;

    case(state)
        FETCH: begin
            irwrite = 1;
            pcupdate = 1;
            alusrcb = 2'b10;
            resultsrc = 2'b10;
        end
        DECODE: begin
            alusrca = 2'b01;
            alusrcb = 2'b01;
        end
        EXECUTER: begin
            alusrca = 2'b10;
            aluop = 2'b10;
        end
        ALUWB: regwrite = 1;
        MEMADR: begin
            alusrca = 2'b10;
            alusrcb = 2'b01;
        end
        EXECUTEI: begin
            alusrca = 2'b10;
            alusrcb = 2'b01;
            aluop = 2'b10;
        end
        JAL: begin
            alusrca = 2'b01;
            alusrcb = 2'b10;
            pcupdate = 1;
        end
        BEQ: begin
            alusrca = 2'b10;
            aluop = 2'b01;
            branch = 1;
        end
        MEMWRITE: begin
            adrsrc = 1;
            memwrite = 1;
        end
        MEMREAD: adrsrc = 1;
        MEMWB: begin
            resultsrc = 2'b01;
            regwrite = 1;
        end
        LUI: begin
            resultsrc = 2'b11;
            regwrite = 1;
        end
        default: ;
    endcase
    
end

// including alu controller instantiation 
ALU_Control alu_dec (
    .ALUOp (aluop),
    .op5   (op[5]),
    .funct75 (funct7b5),
    .funct3 (funct3),
    .control_out (alucontrol)
);

// handling pcwrite branch conditions
logic cond;

always_comb
    case (funct3)
        // BEQ
        3'b000:  cond = zero;   
        // BNE
        3'b001:  cond = ~zero; 
        // BLT 
        3'b100:  cond = ~zero;
        // BGE    
        3'b101:  cond = zero;
        // BLTU    
        3'b110:  cond = ~zero;    
        // BGEU
        3'b111:  cond = zero;  
        default: cond = 1'b0;
    endcase

assign pcwrite = (branch & cond) | pcupdate;

// handling immGen driver
always_comb
    case(op)
        // S-type stores
        7'b0100011: immsrc = 3'b001;  
        // B-type branches
        7'b1100011: immsrc = 3'b010; 
        // U-type: lui, auipc  
        7'b0110111,
        7'b0010111: immsrc = 3'b011;  
        // J-type: jal 
        7'b1101111: immsrc = 3'b100; 
        // I-type loads  
        default:    immsrc = 3'b000;  
    endcase

endmodule