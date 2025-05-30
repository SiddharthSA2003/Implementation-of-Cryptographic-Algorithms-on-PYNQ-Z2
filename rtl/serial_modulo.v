`timescale 1ns / 1ps

module serial_modulo(
    input wire          clk,
    input wire          reset,
    input wire          start,
    input wire [511:0]  A,        // 512-bit input
    output reg [254:0]  result,   // 255-bit reduced output
    output reg          done
    );

    // Curve25519 modulus: p = 2^255 - 19
    localparam P1 = 255'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;
    localparam P2 = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDA;
    localparam P3 = 257'h1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFB4;
    localparam P4 = 258'h3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF68;
    localparam P5 = 259'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED0;
    localparam P6 = 260'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDA0;
    localparam P7 = 261'h1FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFB40;
    
    localparam  IDLE = 2'b00,
                COMP = 2'b01,
                ADD  = 2'b10,
                DONE = 2'b11;
    
    reg  [1:0]   state;
    reg  [262:0] A_temp;

    reg  [254:0] A_low;
    reg  [260:0] A_high;
    
    reg  [262:0] sum;
    
    always @ (posedge clk)
    begin
        if (reset) begin
            A_temp  <= 0;
            A_low   <= 0;
            A_high  <= 0;
            
            sum     <= 0;
            result  <= 0;
            done    <= 0;
            state   <= IDLE;
        end
        else begin
            case (state)
                IDLE  : begin
                            done    <= 0;
                            
                            if (start) begin
                                A_low   <= A[254:0];
                                A_high  <= A[511:255];
                                A_temp  <= 0;
                                state   <= COMP;
                            end
                        end
                COMP  : begin
                            A_temp  <= (A_high << 4) + (A_high << 1) + A_high;
                            state   <= ADD;
                        end
                ADD   : begin
                            sum     <= A_low + A_temp;
                            state   <= DONE;
                        end
                DONE  : begin
                            if (sum[262] == 1) begin
                                sum  <= sum - P7;
                            end
                            else if (sum[261] == 1) begin
                                sum  <= sum - P6;
                            end
                            else if (sum[260] == 1) begin
                                sum  <= sum - P5;
                            end
                            else if (sum[259] == 1) begin
                                sum  <= sum - P4;
                            end
                            else if (sum[258] == 1) begin
                                sum  <= sum - P3;
                            end
                            else if (sum[257] == 1) begin
                                sum  <= sum - P2;
                            end
                            else if (sum >= P1) begin
                                sum  <= sum - P1;
                            end
                            else begin
                                result  <= sum;
                                done    <= 1;
                                state   <= IDLE;
                            end
                        end
            endcase
        end
    end
endmodule
