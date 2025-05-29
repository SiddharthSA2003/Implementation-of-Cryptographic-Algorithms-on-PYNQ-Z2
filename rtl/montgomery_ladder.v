`timescale 1ns / 1ps

module montgomery_ladder #(
    parameter WIDTH = 255,
    parameter W     = 512
)(
    // INPUT
    input wire             mont_clk,
    input wire             mont_reset,
    input wire             mont_valid,
    input wire [WIDTH:0]   mont_data_in,
    
    // OUTPUT
    output reg [WIDTH-1:0] mont_data_out,
    output reg             mont_data_valid
    );

    // Curve25519 prime: 2^255 - 19
    localparam PRIME = 255'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;

    // Internal registers
    reg [WIDTH-1:0] R0x;
    reg [WIDTH-1:0] R0z;
    reg [WIDTH-1:0] R1x;
    reg [WIDTH-1:0] R1z;
    reg [WIDTH-1:0] Rx;
    reg [WIDTH-1:0] Rz;
    reg             da_start;       // Start Point Adder and Point Doubler
    
    reg             mul_start;
    reg [WIDTH:0]   mul_in1;
    reg [WIDTH:0]   mul_in2;
    reg             mod_start;
    reg [W-1:0]     mod_in;
    
    // Counters
    reg [7:0] bit_index;
    
    // Flags
    reg     calc_done;
    
    // Output wires from sub modules
    wire             inv_done;
    wire [WIDTH-1:0] add_Rx;
    wire [WIDTH-1:0] add_Rz;
    wire [WIDTH-1:0] dbl_Rx;
    wire [WIDTH-1:0] dbl_Rz;
    wire [WIDTH-1:0] result_x;
    wire [WIDTH-1:0] z_inv;
    wire             da_done;
    wire [W-1:0]     mul_out;
    wire             mul_done;
    wire [WIDTH-1:0] mod_result;
    wire             mod_done;

    // FSM states
    localparam  IDLE    = 2'b00,
                INIT    = 2'b01,
                WAIT    = 2'b10,
                FINISH  = 2'b11,
                START_I = 4'b0100,
                INVERT  = 4'b0101,
                MUL     = 4'b0110,
                MUL_W   = 4'b0111,
                MOD     = 4'b1000,
                UPDATE  = 4'b1001,
                DONE    = 4'b1010;
                
    reg [3:0] state;
    
    wire [WIDTH-1:0] pd_Rx = mont_data_in[bit_index] ? R1x : R0x;
    wire [WIDTH-1:0] pd_Rz = mont_data_in[bit_index] ? R1z : R0z;
    
    //--------------------------------------------------------------------------
    // Double Add Module
    //--------------------------------------------------------------------------
    
    double_add doubadd(
        .clk        (mont_clk),
        .reset      (mont_reset),
        .start      (da_start),
        .XP         (R0x),
        .ZP         (R0z),
        .XQ         (R1x),
        .ZQ         (R1z),
        .pd_X       (pd_Rx),
        .pd_Z       (pd_Rz),
        .X_out_pd   (dbl_Rx),
        .Z_out_pd   (dbl_Rz),
        .X_out_pa   (add_Rx),
        .Z_out_pa   (add_Rz),
        .done       (da_done)
        );
    
    //--------------------------------------------------------------------------
    // Modulo Inverse
    //--------------------------------------------------------------------------
    
    mod_inverse inv_mod (
        .inv_clk        (mont_clk),
        .inv_reset      (mont_reset),
        .inv_valid      (calc_done),
        .inv_in         (Rz),
        .inv_inverse    (z_inv),
        .inv_data_valid (inv_done)
        );
    
    //--------------------------------------------------------------------------
    // Serial Modulo
    //--------------------------------------------------------------------------
    
    serial_modulo modulo(
        .clk        (mont_clk),
        .reset      (mont_reset),
        .start      (mod_start),
        .A          (mod_in),
        .result     (mod_result),
        .done       (mod_done)
        );
    
    //--------------------------------------------------------------------------
    // 256 bit Multiplier
    //--------------------------------------------------------------------------
    
    multiplier_256 mult1_256(
        .clk        (mont_clk),
        .reset      (mont_reset),
        .start      (mul_start),
        .in1        (mul_in1),
        .in2        (mul_in2),
        .out        (mul_out),
        .done       (mul_done)
        );
    
    //--------------------------------------------------------------------------
    // Main Montgomery Ladder Control
    //--------------------------------------------------------------------------

    always @(posedge mont_clk) begin
        if (mont_reset) begin
            Rx              <= 0;
            Rz              <= 0;
            R0x             <= 0;
            R0z             <= 0;
            R1x             <= 0;
            R1z             <= 0;
            
            mul_start       <= 0;
            mul_in1         <= 0;
            mul_in2         <= 0;
            
            mod_start       <= 0;
            mod_in          <= 0;
            
            bit_index       <= 0;
            da_start        <= 0;
            
            calc_done       <= 0;
	        
            state           <= IDLE;
            mont_data_out   <= 0;
            mont_data_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    mont_data_valid <= 0;
                    if (mont_valid) begin
                        R0x         <= 1;
                        R0z         <= 0;
                        R1x         <= 255'h09;
                        R1z         <= 1;
                        bit_index   <= WIDTH;
                        state       <= INIT;
                    end
                end
                
                INIT: begin
                    da_start    <= 1;
                    state       <= WAIT;
                end
                
                WAIT: begin
                    da_start <= 0;
                    
                    if (da_done) begin
                        if (mont_data_in[bit_index]) begin
                            R0x <= add_Rx;
                            R0z <= add_Rz;
                            R1x <= dbl_Rx;
                            R1z <= dbl_Rz;
                        end else begin
                            R1x <= add_Rx;
                            R1z <= add_Rz;
                            R0x <= dbl_Rx;
                            R0z <= dbl_Rz;
                        end
                        
                        if (bit_index == 0) begin
                            state   <= FINISH;
                        end else begin
                            bit_index   <= bit_index - 1;
                            state       <= INIT;
                        end
                    end
                end
                
                FINISH: begin
                    Rx              <= R0x;
                    Rz              <= R0z;
                    state           <= START_I;
                end
                
                START_I: begin
                    calc_done   <= 1;
                    state       <= INVERT;
                end
                
                INVERT: begin
                    calc_done <= 0;
                    if (inv_done) begin
                        mul_in1     <= Rx;
                        mul_in2     <= z_inv;
                        state       <= MUL;
                    end
                end
                
                MUL : begin
                    mul_start   <= 1;
                    state       <= MUL_W;
                end
                
                MUL_W : begin
                    mul_start   <= 0;
                    
                    if (mul_done) begin
                        mod_in  <= mul_out;
                        state   <= MOD;
                    end
                end
                
                MOD : begin
                    mod_start   <= 1;
                    state       <= UPDATE;
                end
                
                UPDATE: begin
                    mod_start   <= 0;
                    
                    if (mod_done) begin
                        mont_data_out   <= mod_result;
                        state           <= DONE;
                    end
                end
                
                DONE: begin
                    mont_data_valid <= 1;
                    state           <= IDLE;
                end
            endcase
        end
    end
    
endmodule
