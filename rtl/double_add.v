`timescale 1ns / 1ps

module double_add #(
    parameter WIDTH = 255,  // Curve25519 uses 255-bit numbers
    parameter W = 512
)(
    // INPUT
    input wire clk,
    input wire reset,
    input wire start,
    
    // Input points in projective coordinates (X:Z)
    input wire [WIDTH-1:0] XP, ZP,      // Point P
    input wire [WIDTH-1:0] XQ, ZQ,      // Point Q
    input wire [WIDTH-1:0] pd_X, pd_Z,
    
    // OUTPUT
    output reg [WIDTH-1:0] X_out_pa,
    output reg [WIDTH-1:0] Z_out_pa,
    output reg [WIDTH-1:0] X_out_pd,    // Result X coordinate
    output reg [WIDTH-1:0] Z_out_pd,    // Result Z coordinate
    output wire            done
    );
    
    // Curve25519 parameter A = (486662 + 2)/4 = 121666 (0x1db42)
    localparam a = 255'h1db42;

    // Prime modulus for Curve25519: p = 2^255 - 19
    localparam PRIME = 255'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;

    // Intermediate registers
    reg [WIDTH:0] XZ_plus;
    reg [WIDTH:0] XZ_minus;
    reg [WIDTH:0] XZ;
    reg [WIDTH:0] XZ_temp;
    reg [WIDTH:0] X_plus_sq;
    reg [WIDTH:0] X_minus_sq;
    
    reg [WIDTH:0]   A;
    reg [WIDTH:0]   B;
    reg [WIDTH:0]   C;
    reg [WIDTH:0]   D;
    reg [WIDTH:0]   DA;
    reg [WIDTH:0]   CB;
    reg [WIDTH:0]   E;
    reg [WIDTH:0]   F;
    reg [WIDTH+3:0] EE;
    reg [WIDTH+3:0] EE_temp;
    
    // Multiplier 256 registers
    reg           mul1_start;
    reg [WIDTH:0] mul1_in1;
    reg [WIDTH:0] mul1_in2;
    reg           mul2_start;
    reg [WIDTH:0] mul2_in1;
    reg [WIDTH:0] mul2_in2;
    
    // Serial modulo registers
    reg         mod1_start;
    reg         mod2_start;
    reg [W-1:0] mod1_in;
    reg [W-1:0] mod2_in;
    
    // Multiplier 256 wires
    wire [W-1:0] mul1_result;
    wire [W-1:0] mul2_result;
    wire         mul1_done;
    wire         mul2_done;
    
    // Serial modulo wires
    wire [WIDTH-1:0] mod1_result;
    wire [WIDTH-1:0] mod2_result;
    wire             mod1_done;
    wire             mod2_done;
    
    reg pa_done;
    reg pd_done;
    
    reg [3:0] pd_state;
    reg [3:0] pa_state;
    
    multiplier_256 mult1_256_double_add(
        .clk        (clk),
        .reset      (reset),
        .start      (mul1_start),
        .in1        (mul1_in1),
        .in2        (mul1_in2),
        .out        (mul1_result),
        .done       (mul1_done)
        );
    
    multiplier_256 mult2_256_double_add(
        .clk        (clk),
        .reset      (reset),
        .start      (mul2_start),
        .in1        (mul2_in1),
        .in2        (mul2_in2),
        .out        (mul2_result),
        .done       (mul2_done)
        );
        
    serial_modulo modulo1_double_add(
        .clk        (clk),
        .reset      (reset),
        .start      (mod1_start),
        .A          (mod1_in),
        .result     (mod1_result),
        .done       (mod1_done)
        );
        
    serial_modulo modulo2_double_add(
        .clk        (clk),
        .reset      (reset),
        .start      (mod2_start),
        .A          (mod2_in),
        .result     (mod2_result),
        .done       (mod2_done)
        );
    
    always @ (posedge clk)
    begin
        if (reset) begin
            // Point Doubling registers
            XZ_plus         <= 0;
            XZ_minus        <= 0;
            XZ              <= 0;
            XZ_temp         <= 0;
            X_plus_sq       <= 0;
            X_minus_sq      <= 0;
            
            X_out_pd        <= 0;
            Z_out_pd        <= 0;
            
            mul1_in1        <= 0;
            mul1_in2        <= 0;
            mod1_in         <= 0;
            
            pd_state        <= 0;
            pd_done         <= 0;
            
            // Point Addition registers
            A               <= 0;
            B               <= 0;
            C               <= 0;
            D               <= 0;
            DA              <= 0;
            CB              <= 0;
            E               <= 0;
            F               <= 0;
            EE              <= 0;
            EE_temp         <= 0;
            
            X_out_pa        <= 0;
            Z_out_pa        <= 0;
            
            mul2_in1        <= 0;
            mul2_in2        <= 0;
            mod2_in         <= 0;
            
            pa_state        <= 0;
            pa_done         <= 0;
        end
        else begin
            //=================================================================================
            // Point Doubling Logic
            //=================================================================================
            
            case (pd_state)
                0 : begin

                        if (start) begin
                            XZ_plus         <= pd_X + pd_Z;
                            XZ_minus        <= (pd_X > pd_Z) ? pd_X - pd_Z : pd_X + PRIME - pd_Z;
                            
                            pd_state        <= pd_state + 1;
                        end
                    end
                1 : begin
                        mul1_in1    <= XZ_plus;
                        mul1_in2    <= XZ_plus;
                
                        mul1_start  <= 1;
                        
                        pd_state    <= pd_state + 1;
                    end
                2 : begin
                        mul1_start  <= 0;
                        
                        if (mul1_done) begin
                            mod1_in     <= mul1_result;
                    
                            mod1_start  <= 1;
                        
                            pd_state    <= pd_state + 1;
                        end
                    end
                3 : begin
                        mod1_start  <= 0;
                        
                        mul1_in1    <= XZ_minus;
                        mul1_in2    <= XZ_minus;
                
                        mul1_start  <= 1;
                        
                        pd_state    <= pd_state + 1;
                    end
                4 : begin
                        mul1_start  <= 0;
                        
                        if (mul1_done) begin
                            mod1_in     <= mul1_result;
                            
                            pd_state    <= pd_state + 1;
                        end
                    end
                5 : begin
                        if (mod1_done) begin
                            X_plus_sq   <= mod1_result;
                            
                            mod1_start  <= 1;
                            
                            pd_state    <= pd_state + 1;
                        end
                    end
                6 : begin
                        mod1_start  <= 0;
                        
                        if (mod1_done) begin
                            X_minus_sq  <= mod1_result;
                            
                            pd_state    <= pd_state + 1;
                        end
                    end
                7 : begin
                        mul1_in1    <= X_plus_sq;
                        mul1_in2    <= X_minus_sq;
                
                        mul1_start  <= 1;
                
                        XZ          <= (X_plus_sq > X_minus_sq) ? X_plus_sq - X_minus_sq : X_plus_sq + PRIME - X_minus_sq;
                        
                        pd_state    <= pd_state + 1;
                    end
                8 : begin
                        mul1_start  <= 0;
                        
                        if (mul1_done) begin
                            mod1_in     <= mul1_result;
                    
                            mod1_start  <= 1;
                            
                            pd_state    <= pd_state + 1;
                        end
                    end
                9 : begin
                        mod1_start  <= 0;
                        
                        mul1_in1    <= XZ;
                        mul1_in2    <= a;
                
                        mul1_start  <= 1;
                        
                        pd_state    <= pd_state + 1;
                    end
               10 : begin
                        mul1_start  <= 0;
                        
                        if (mul1_done) begin
                            mod1_in     <= mul1_result;
                            
                            pd_state    <= pd_state + 1;
                        end
                    end
               11 : begin
                        if (mod1_done) begin
                            X_out_pd    <= mod1_result;
                            
                            mod1_start  <= 1;
                            
                            pd_state    <= pd_state + 1;
                        end
                    end
               12 : begin
                        mod1_start  <= 0;
                        
                        if (mod1_done) begin
                            XZ_temp     <= mod1_result + X_minus_sq;
                            
                            pd_state    <= pd_state + 1;
                        end
                    end
               13 : begin
                        mul1_in1    <= XZ_temp;
                        mul1_in2    <= XZ;
                    
                        mul1_start  <= 1;
                        
                        pd_state    <= pd_state + 1;
                    end
               14 : begin
                        mul1_start  <= 0;
                        
                        if (mul1_done) begin
                            mod1_in     <= mul1_result;
                    
                            mod1_start  <= 1;
                            
                            pd_state    <= pd_state + 1;
                        end
                    end
               15 : begin
                        mod1_start  <= 0;
                        
                        if (mod1_done) begin
                            Z_out_pd    <= mod1_result;
                            
                            pd_done     <= 1;
                            
                            pd_state    <= 0;
                        end
                    end
            endcase
            
            //=================================================================================
            // Point Addition Logic
            //=================================================================================
            
            case (pa_state)
                0 : begin

                        if (start) begin
                            A           <= XP + ZP;
                            B           <= (XP > ZP) ? XP - ZP : XP + PRIME - ZP;
                            C           <= XQ + ZQ;
                            D           <= (XQ > ZQ) ? XQ - ZQ : XQ + PRIME - ZQ;
                
                            pa_state    <= pa_state + 1;
                        end
                    end
                1 : begin
                        mul2_in1    <= A;
                        mul2_in2    <= D;
                        
                        mul2_start  <= 1;
                        
                        pa_state    <= pa_state + 1;
                    end
                2 : begin
                        mul2_start  <= 0;
                        
                        if (mul2_done) begin
                            mod2_in     <= mul2_result;
                    
                            mod2_start  <= 1;
                            
                            pa_state    <= pa_state + 1;
                        end
                    end
                3 : begin
                        mod2_start  <= 0;
                        
                        mul2_in1    <= C;
                        mul2_in2    <= B;
                
                        mul2_start  <= 1;
                        
                        pa_state    <= pa_state + 1;
                    end
                4 : begin
                        mul2_start  <= 0;
                        
                        if (mul2_done) begin
                            mod2_in     <= mul2_result;
                            
                            pa_state    <= pa_state + 1;
                        end
                    end
                5 : begin
                        if (mod2_done) begin
                            DA          <= mod2_result;
                            
                            mod2_start  <= 1;
                            
                            pa_state    <= pa_state + 1;
                        end
                    end
                6 : begin
                        mod2_start  <= 0;
                        
                        if (mod2_done) begin
                            E           <= DA + mod2_result;
                            F           <= (DA > mod2_result) ? DA - mod2_result : DA + PRIME - mod2_result;
                            
                            pa_state    <= pa_state + 1;
                        end
                    end
                7 : begin
                        mul2_in1    <= E;
                        mul2_in2    <= E;
                        
                        mul2_start  <= 1;
                        
                        pa_state    <= pa_state + 1;
                    end
                8 : begin
                        mul2_start  <= 0;
                        
                        if (mul2_done) begin
                            mod2_in     <= mul2_result;
                    
                            mod2_start  <= 1;
                            
                            pa_state    <= pa_state + 1;
                        end
                    end
                9 : begin
                        mod2_start  <= 0;
                        
                        mul2_in1    <= F;
                        mul2_in2    <= F;
                        
                        mul2_start  <= 1;
                        
                        pa_state    <= pa_state + 1;
                    end
               10 : begin
                        mul2_start  <= 0;
                        
                        if (mul2_done) begin
                            mod2_in     <= mul2_result;
                            
                            pa_state    <= pa_state + 1;
                        end
                    end
               11 : begin
                        if (mod2_done) begin
                            EE          <= mod2_result;
                            
                            mod2_start  <= 1;
                            
                            pa_state    <= pa_state + 1;
                        end
                    end
               12 : begin
                        mod2_start  <= 0;
                        
                        if (mod2_done) begin
                            Z_out_pa    <= mod2_result;
                            
                            EE_temp     <= (EE << 3) + EE;
                            
                            pa_state    <= pa_state + 1;
                        end
                    end
               13 : begin
                        mod2_in     <= EE_temp;
                    
                        mod2_start  <= 1;
                            
                        pa_state    <= pa_state + 1;
                    end
               14 : begin
                        mod2_start  <= 0;
                        
                        if (mod2_done) begin
                            X_out_pa    <= mod2_result;
                            
                            pa_done     <= 1;
                            
                            pa_state    <= 0;
                        end
                    end
            endcase
            
            if (pa_done && pd_done) begin
                pa_done     <= 0;
                pd_done     <= 0;
            end
        end
    end
    
    assign done = (pa_done && pd_done);
endmodule