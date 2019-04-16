import rv32i_types::*;

module gshare  #(parameter pht_size = 8, parameter pbr_size = 5)(
    input logic clk,

    // predict signals 
    input rv32i_word fetch_pc, 
    output logic [pbr_size-1:0] bhr_out,    // branch history register state to exec state -> *register*  
    output logic pred_is_taken,	            // ouput taken prediction 
    // update signals 
    input rv32i_opcode opcode,              // opcode from EXEC- if is br_en, update 
    input rv32i_word exec_pc,
    input logic pcmux_sel,                  // shows was BR taken in EXEC - use to update BHR as up/down  
    input logic [pbr_size-1:0] prev_bhr     // old BHR we use to access PHT 
); 

// PHT: 00 SN | 01 WN | 10 WT | 11 ST
logic [pht_size-1:0][1:0] pattern_history_table;
logic [pbr_size-1:0] branch_history_register; 
logic [2:0] pht_key, prev_pht_key;    // access pht (size 3: 2^3 = 8 = pht_size)
logic [1:0] counter; 

initial begin 
    for(int i = 0; i < pht_size; i++) begin 
        pattern_history_table[i] = 2'b01;       // initalize all pattern histoy table to WNT
    end
    branch_history_register = 0;
end 

/*
 * Two options:
 * 1. Predict: 
 *      - takes in PC from fetch
 *      - outputs pred_is_taken based on curr BHR and PC[6:2] (MST of counter val)
 * 2. Update:
 *      - take in PC from EXEC and old Branch History Register state
 *      - update Pattern History Table based on if branch was taken (pcmux_sel or ~pcmux_sel)
 *      - update BHR based on was_br_taken using sat counter 
*/ 

always_ff @(posedge clk) begin 
    // predict first
    pht_key <= (fetch_pc[6:2] ^ branch_history_register) & 3'b111;    // create 3-bit key for BHT 
    pred_is_taken <= (pattern_history_table[pht_key] >> 1) & 1'b1;    // take MST of PHT as is taken 
    bhr_out <= branch_history_register;

    // then update 
    prev_pht_key <= (exec_pc[6:2] ^ prev_bhr) & 3'b111;
    if(opcode == op_br) begin 
        counter <= (pattern_history_table[prev_pht_key] & pcmux_sel) ? 
                        pattern_history_table[prev_pht_key] + 1 : pattern_history_table[prev_pht_key] - 1; 
        pattern_history_table[prev_pht_key] <= counter; 
    end 
    branch_history_register <= (branch_history_register << 1) & pcmux_sel;  // shift and add newest was taken
end 

endmodule: gshare 