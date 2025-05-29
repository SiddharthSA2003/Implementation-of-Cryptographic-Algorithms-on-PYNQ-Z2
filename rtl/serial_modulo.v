`timescale 1ns / 1ps

module serial_modulo #( 
    parameter WIDE_IN  = 512,    // Width of input A
    parameter WIDE_MOD = 255     // Width of modulus P
)(
    input  wire                 clk,
    input  wire                 reset,
    input  wire                 start,
    input  wire [WIDE_IN-1:0]   A,
    output reg  [WIDE_MOD-1:0]  result,
    output reg                  done
);
    
    localparam  Prime = 255'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED;

    reg  [WIDE_IN-1: 0] temp;
    reg  [8:0]          bit_index;  // Can count up to 512
    
    wire [WIDE_MOD:0]   temp_slice;
    
    localparam  IDLE        = 2'b00,
                SUBTRACT    = 2'b01,
                FINALIZE    = 2'b10;
                
    reg [1:0] state;
    
    assign temp_slice = temp[bit_index -: WIDE_MOD + 1];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            temp        <= 0;
            bit_index   <= 0;
            result      <= 0;
            done        <= 0;
            state       <= IDLE;
        end
        else begin
            case (state)
                IDLE    : begin
                              done  <= 0;
                              
                              if (start) begin
                                  temp          <= A;
                                  bit_index     <= WIDE_IN - 1;
                                  state         <= SUBTRACT;
                              end
                          end
                SUBTRACT: begin
                              if (bit_index >= WIDE_MOD) begin
                                  if (temp[bit_index] == 1) begin
                                      temp[bit_index -: WIDE_MOD + 1] <= temp_slice - Prime;
                                  end
                                  bit_index <= bit_index - 1;
                              end
                              else
                                  state <= FINALIZE;
                          end
                FINALIZE: begin
                              if (temp[WIDE_MOD:0] >= Prime)
                                  result <= temp[WIDE_MOD-1:0] - Prime;
                              else
                                  result <= temp[WIDE_MOD-1:0];
                              
                              done  <= 1;
                              
                              state <= IDLE;
                          end
            endcase
        end
    end
endmodule