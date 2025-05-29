`timescale 1ns / 1ps

module mod_inverse #(parameter WIDTH = 255)(
    // INPUT
    input wire             inv_clk,
    input wire             inv_reset,
    input wire             inv_valid,
    input wire [WIDTH-1:0] inv_in,
    
    // OUTPUT
    output reg [WIDTH-1:0] inv_inverse,
    output reg             inv_data_valid
    );
    
    localparam  prime = 255'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;
    
    // Intermediate registers
    reg [WIDTH-1:0] u;
    reg [WIDTH-1:0] v;
    reg [WIDTH-1:0] x;
    reg [WIDTH-1:0] y;
    
    // FSM states
    reg [1:0] state;
    
    localparam  IDLE  = 2'b00,
                LOOP  = 2'b01,
                UPD   = 2'b10,
                DONE  = 2'b11;
    
    wire [WIDTH:0] X = (x + prime) >> 1;
    wire [WIDTH:0] Y = (y + prime) >> 1;
    
    always @ (posedge inv_clk)
    begin
        if (inv_reset) begin
            u               <= 0;
            v               <= 0;
            x               <= 0;
            y               <= 0;
            
            state           <= IDLE;
            inv_inverse     <= 0;
            inv_data_valid  <= 0;
        end
        else begin
            case (state)
                IDLE  : begin
                            inv_data_valid  <= 0;
                            
                            if (inv_valid) begin
                                u       <= inv_in;
                                v       <= prime;
                                x       <= 1;
                                y       <= 0;
                                state   <= LOOP;
                            end
                        end
                        
                LOOP  : begin
                            if (u == 1 || v == 1) begin
                                state   <= UPD;
                            end
                            
                            else begin
                                if (u % 2 == 0) begin
                                    u   <= u >> 1;
                                    
                                    if (x % 2 == 0) begin
                                        x   <= x >> 1;
                                    end
                                    else begin
                                        x   <= (X >= prime) ? X - prime : X[WIDTH-1:0];
                                    end
                                end
                                
                                else if (v % 2 == 0) begin
                                    v   <= v >> 1;
                                    
                                    if (y % 2 == 0) begin
                                        y   <= y >> 1;
                                    end
                                    else begin
                                        y   <= (Y >= prime) ? Y - prime : Y[WIDTH-1:0];
                                    end
                                end
                                
                                else begin
                                    if (u > v) begin
                                        u   <= u - v;
                                        x   <= (x >= y) ? x - y : x + prime - y;
                                    end
                                    
                                    else begin
                                        v   <= v - u;
                                        y   <= (y >= x) ? y - x : y + prime - x;
                                    end
                                end
                            end
                        end
                        
                UPD   : begin
                            if (u == 1) begin
                                inv_inverse <= x;
                            end
                            else begin
                                inv_inverse  <= y;
                            end
                            
                            state   <= DONE;
                        end
                        
                DONE  : begin
                            inv_data_valid  <= 1;
                            u               <= 0;
                            v               <= 0;
                            x               <= 0;
                            y               <= 0;
                            state           <= IDLE;
                        end
            endcase
        end
    end
endmodule