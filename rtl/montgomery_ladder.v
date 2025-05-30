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
    output reg [WIDTH-1:0] Rx,
    output reg [WIDTH-1:0] Rz,
    output reg             mont_data_valid
    );

    // Curve25519 prime: 2^255 - 19
    localparam PRIME = 255'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;

    // Internal registers
    reg [WIDTH:0]   private_key;
    reg [WIDTH-1:0] R0x;
    reg [WIDTH-1:0] R0z;
    reg [WIDTH-1:0] R1x;
    reg [WIDTH-1:0] R1z;
    reg             da_start;       // Start Point Adder and Point Doubler
    
    // Counters
    reg [7:0] bit_index;
    
    // Output wires from sub modules
    wire [WIDTH-1:0] add_Rx;
    wire [WIDTH-1:0] add_Rz;
    wire [WIDTH-1:0] dbl_Rx;
    wire [WIDTH-1:0] dbl_Rz;
    wire             da_done;

    // FSM states
    localparam  IDLE    = 2'b00,
                INIT    = 2'b01,
                WAIT    = 2'b10,
                FINISH  = 2'b11;
                
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
            
            private_key     <= 0;
            
            bit_index       <= 0;
            da_start        <= 0;
	        
            state           <= IDLE;
            mont_data_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    mont_data_valid <= 0;
                    if (mont_valid) begin
                        private_key <= mont_data_in;
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
                        if (private_key[bit_index]) begin
                            R0x <= add_Rx;
                            R0z <= add_Rz;
                            R1x <= dbl_Rx;
                            R1z <= dbl_Rz;
                        end
                        else begin
                            R1x <= add_Rx;
                            R1z <= add_Rz;
                            R0x <= dbl_Rx;
                            R0z <= dbl_Rz;
                        end
                        
                        if (bit_index == 0) begin
                            state   <= FINISH;
                        end
                        else begin
                            bit_index   <= bit_index - 1;
                            state       <= INIT;
                        end
                    end
                end
                
                FINISH: begin
                    Rx              <= R0x;
                    Rz              <= R0z;
                    mont_data_valid <= 1;
                    state           <= IDLE;
                end
            endcase
        end
    end
    
endmodule
