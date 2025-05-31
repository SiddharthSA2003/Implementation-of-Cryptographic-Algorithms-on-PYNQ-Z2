`timescale 1ns / 1ps

module chunk_divider(
    // INPUT
    input  wire         chunk_div_clk,
    input  wire         chunk_div_reset,
    input  wire         chunk_div_valid,
    input  wire         encryp_decryp,
    input  wire         m_axis_ready,
    input  wire [255:0] public_key,
    input  wire [63:0]  nonce,
    input  wire [63:0]  counter,
    input  wire [511:0] chunk_div_data_in,
    
    // OUTPUT
    output reg  [31:0]  chunk_div_data_out,
    output reg          chunk_div_data_valid,
    output reg          chunk_div_last_byte
);

    reg [4:0]   word_index;           // 4 bits for counting 16 to 1
    reg         sending;
    reg [511:0] data_buffer;          // Buffer for input data
    reg [255:0] public_key_reg;
    reg [63:0]  nonce_reg;
    reg [63:0]  counter_reg;
    
    reg         public_key_sent;
    reg         nonce_sent;
    reg         counter_sent;
    reg         ciphertext_sent;
    
    localparam  ENCRYP = 1'b0,
                DECRYP = 1'b1;

    always @(posedge chunk_div_clk) begin
        if (chunk_div_reset) begin
            word_index              <= 16;
            chunk_div_data_out      <= 0;
            chunk_div_data_valid    <= 0;
            sending                 <= 0;
            
            data_buffer             <= 0;
            public_key_reg          <= 0;
            nonce_reg               <= 0;
            counter_reg             <= 0;
            
            public_key_sent         <= 0;
            nonce_sent              <= 0;
            counter_sent            <= 0;
            ciphertext_sent         <= 0;
            chunk_div_last_byte     <= 0;
        end
        else begin
            case (encryp_decryp)
                ENCRYP: begin
                            if (chunk_div_valid && !sending) begin
                                public_key_reg  <= public_key;
                                nonce_reg       <= nonce;
                                counter_reg     <= counter;
                                data_buffer     <= chunk_div_data_in;
                                word_index      <= 8;
                                sending         <= 1;
                            end

                            else if (sending & m_axis_ready == 1) begin
                                if (~public_key_sent) begin
                                    chunk_div_data_out    <= public_key_reg[word_index*32 - 1 -: 32];
                                    chunk_div_data_valid  <= 1;
                                    
                                    if (word_index == 1) begin
                                        word_index      <= 2;
                                        public_key_sent <= 1;
                                    end
                                    else begin
                                        word_index  <= word_index - 1;
                                    end
                                end
                                else if (~nonce_sent) begin
                                    chunk_div_data_out    <= nonce_reg[word_index*32 - 1 -: 32];
                                    chunk_div_data_valid  <= 1;
                                    
                                    if (word_index == 1) begin
                                        word_index  <= 2;
                                        nonce_sent  <= 1;
                                    end
                                    else begin
                                        word_index  <= word_index - 1;
                                    end
                                end
                                else if (~counter_sent) begin
                                    chunk_div_data_out    <= counter_reg[word_index*32 - 1 -: 32];
                                    chunk_div_data_valid  <= 1;
                                    
                                    if (word_index == 1) begin
                                        word_index      <= 16;
                                        counter_sent    <= 1;
                                    end
                                    else begin
                                        word_index  <= word_index - 1;
                                    end
                                end
                                else if (~ciphertext_sent) begin
                                    chunk_div_data_out    <= data_buffer[word_index*32 -1 -: 32];
                                    chunk_div_data_valid  <= 1;
                
                                    if (word_index == 1) begin
                                        sending             <= 0;
                                        ciphertext_sent     <= 1;
                                        chunk_div_last_byte <= 1;
                                        word_index          <= 16;
                                    end
                                    else begin
                                        word_index <= word_index - 1;
                                    end
                                end
                            end
            
                            else if (chunk_div_last_byte) begin
                                chunk_div_last_byte     <= 0;
                                public_key_sent         <= 0;
                                nonce_sent              <= 0;
                                counter_sent            <= 0;
                                ciphertext_sent         <= 0;
                                chunk_div_data_valid    <= 0;
                            end
                        end
                DECRYP: begin
                            if (chunk_div_valid && !sending) begin
                                data_buffer <= chunk_div_data_in;
                                word_index  <= 16;
                                sending     <= 1;
                            end

                            else if (sending) begin
                                chunk_div_data_out    <= data_buffer[word_index*32 -1 -: 32];
                                chunk_div_data_valid  <= 1;
                
                                if (word_index == 1 & m_axis_ready == 1) begin
                                    sending             <= 0;
                                    chunk_div_last_byte <= 1;
                                    word_index          <= 16;
                                end
                                else if (m_axis_ready == 1) begin
                                    word_index <= word_index - 1;
                                end
                            end
            
                            else begin
                                chunk_div_last_byte     <= 0;
                                chunk_div_data_valid    <= 0;
                            end
                        end
            endcase
        end
    end
endmodule
