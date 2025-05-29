`timescale 1ns / 1ps

module chunk_integrator(
    // INPUT
    input  wire         chunk_int_clk,
    input  wire         chunk_int_reset,
    input  wire         s_axis_ready,
    input  wire         chunk_int_valid,
    input  wire         encryp_decryp,           // Encryption when LOW and Decryption when HIGH
    input  wire [31:0]  chunk_int_data_in,
    
    // OUTPUT
    output reg  [255:0] public_key,
    output reg  [63:0]  nonce,
    output reg  [63:0]  counter,
    output reg  [511:0] chunk_int_data_out,
    output reg          chunk_int_data_valid
);

    reg [4:0]   word_index;           // 4 bits for counting 16 to 1
    reg         public_key_received;
    reg         nonce_received;
    reg         counter_received;
    
    localparam  ENCRYP = 1'b0,
                DECRYP = 1'b1;

    always @(posedge chunk_int_clk) begin
        if (chunk_int_reset) begin
            word_index              <= 16;
            chunk_int_data_out      <= 0;
            chunk_int_data_valid    <= 0;
            
            public_key_received     <= 0;
            nonce_received          <= 0;
            counter_received        <= 0;
            
            public_key              <= 0;
            nonce                   <= 0;
            counter                 <= 0;
        end
        
        else begin
            case (encryp_decryp)
                ENCRYP: begin
                            if (chunk_int_valid & s_axis_ready) begin
                                chunk_int_data_out[word_index*32 - 1 -: 32]   <= chunk_int_data_in;
                                
                                if (word_index == 1) begin
                                    chunk_int_data_valid    <= 1;
                                    word_index              <= 16;
                                end else begin
                                    word_index <= word_index - 1;
                                end
                            end
            
                            else begin
                                chunk_int_data_valid    <= 0;
                            end
                        end
                DECRYP: begin
                            if (chunk_int_valid & s_axis_ready) begin
                                if (~public_key_received) begin
                                    public_key[word_index*32 - 257 -: 32]   <= chunk_int_data_in;
                                    
                                    if (word_index == 9) begin
                                        word_index          <= 2;
                                        public_key_received <= 1;
                                    end
                                    else begin
                                        word_index <= word_index - 1;
                                    end
                                end
                                else if (~nonce_received) begin
                                    nonce[word_index*32 - 1 -: 32]    <= chunk_int_data_in;
                                    
                                    if (word_index == 1) begin
                                        word_index      <= 2;
                                        nonce_received  <= 1;
                                    end
                                    else begin
                                        word_index <= word_index - 1;
                                    end
                                end
                                else if (~counter_received) begin
                                    counter[word_index*32 - 1 -: 32]  <= chunk_int_data_in;
                                    
                                    if (word_index == 1) begin
                                        word_index          <= 16;
                                        counter_received    <= 1;
                                    end
                                    else begin
                                        word_index <= word_index - 1;
                                    end
                                end
                                else if (~chunk_int_data_valid) begin
                                    chunk_int_data_out[word_index*32 - 1 -: 32]   <= chunk_int_data_in;
                                    
                                    if (word_index == 1) begin
                                        word_index              <= 16;
                                        chunk_int_data_valid    <= 1;
                                    end
                                    else begin
                                        word_index <= word_index - 1;
                                    end
                                end
                            end
            
                            else if (chunk_int_data_valid) begin
                                public_key_received     <= 0;
                                nonce_received          <= 0;
                                counter_received        <= 0;
                                chunk_int_data_valid    <= 0;
                            end
                        end
            endcase
        end
    end
endmodule
