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
    output logic       regwrite
    );

logic branch, pcuupdate;
logic[1:0] aluop;

// defining enums for each state of the controller FSM
typedef enum logic[3:0] {FETCH, DECODE, EXECUTER, ALUWB} statetype;
// declaring statetypes to keep track of current and next state
statetype state, nextstate;


// always block setting current state
always_ff @(posedge clk, posedge reset) begin
    // fetch is first state in FSM, so if reset go back to beginning
    if (reset) state <= FETCH;
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
                // default to fetch
                default: nextstate = FETCH;
            endcase
        // next step from EXECUTER is ALUWB
        EXECUTER: nextstate = ALUWB;
        ALUWB: nextstate = FETCH;
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
    pcuupdate = 0;
    branch = 0;
    alusrca = 2'b00;
    alusrcb = 2'b00;
    aluop = 2'b00;
    resultsrc = 2'b00;

    case(state)
        FETCH: begin
            irwrite = 1;
            pcuupdate = 1;
            alusrcb = 2'b10;
            resultsrc = 2'b10;
        end
        DECODE: begin
            alusrca = 2'b01;
            alusrcb = 2'b01;
        end
        EXECUTER: begin
            alusrca = 2'b10;
            alu_op = 2'b10;
        end
        ALUWB: regwrite = 1;
        default: ;
    endcase
    
end

// including alu controller instantiation 
ALU_Control alu_dec (
    .ALUOp (aluop),
    .funct7 (funct7b5),
    .funct3 (funct3),
    .Control_out (alu_control)
)

// engage pc write enable only if pc update is set or if branch is taken (rs1-rs2=0)
// TODO: this only handles BEQ, so replace zero with a "condition met" signal determined by funct3
assign pcwrite  = (branch & zero) | pcuupdate;
