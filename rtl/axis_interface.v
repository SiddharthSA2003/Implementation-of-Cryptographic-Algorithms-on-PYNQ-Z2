`timescale 1ns / 1ps

module axis_interface(
    input  wire         axis_clk,
    input  wire         axis_reset_n,
    input  wire         encryp_decryp,          // Encryption when LOW and Decryption when HIGH
    
    // Slave i/f
    input  wire         s_axis_valid,
    input  wire [31:0]  s_axis_data,            // MSB is received first
    output wire         s_axis_ready,
    
    // Master i/f
    input  wire         m_axis_ready,
    output  reg         m_axis_valid,
    output  reg [31:0]  m_axis_data,            // MSB is transmitted first
    output  reg         m_axis_last
    );
    
    reg          chacha_valid;
    reg  [255:0] chacha_key;
    reg  [511:0] chacha_data_in;
    reg          chacha_data_in_valid;
    reg          chacha_data_out_val;
    reg  [63:0]  chacha_nonce;
    reg  [63:0]  chacha_counter;
    
    reg  [255:0] public_key_out;
    reg  [63:0]  nonce_out;
    reg  [63:0]  counter_out;
    
    reg          chunk_div_valid;
    reg  [511:0] chunk_div_data_in;
    
    reg  [31:0]  session_id;
    reg  [31:0]  block_counter;
    reg  [63:0]  nonce_gen;
    reg  [63:0]  counter_gen;
    
    wire [255:0] public_key_received;
    wire [63:0]  chacha_nonce_received;
    wire [63:0]  chacha_counter_received;
    wire [511:0] chunk_int_data_out;
    wire         chunk_int_data_valid;
    
    wire [511:0] chacha_data_out;
    wire         chacha_data_out_valid;
    
    wire [254:0] crypto_data_out;
    wire         crypto_data_valid;
    
    wire [31:0]  chunk_div_data_out;
    wire         chunk_div_data_valid;
    wire         chunk_div_last_byte;
    
    assign s_axis_ready = (crypto_data_valid == 1);
    
    localparam  ENCRYP = 1'b0,
                DECRYP = 1'b1;
    
    chunk_integrator chunk_int(
        .chunk_int_clk          (axis_clk),
        .chunk_int_reset        (~axis_reset_n),
        .s_axis_ready           (s_axis_ready),
        .chunk_int_valid        (s_axis_valid),
        .encryp_decryp          (encryp_decryp),
        .chunk_int_data_in      (s_axis_data),
        .public_key             (public_key_received),
        .nonce                  (chacha_nonce_received),
        .counter                (chacha_counter_received),
        .chunk_int_data_out     (chunk_int_data_out),
        .chunk_int_data_valid   (chunk_int_data_valid)
        );
    
    crypto_top crypt(
        .crypto_clk             (axis_clk),
        .crypto_reset           (~axis_reset_n),
        .top_ready              (m_axis_ready),
        .crypto_data_out        (crypto_data_out),
        .crypto_data_valid      (crypto_data_valid)
        );
    
    chacha_core chacha(
        .clk                    (axis_clk),
        .reset_n                (axis_reset_n),
        .init                   (chacha_valid),
        .next                   (1'b0),
        .key                    (chacha_key),
        .keylen                 (1'b1),
        .iv                     (chacha_nonce),
        .ctr                    (chacha_counter),
        .rounds                 (5'd20),
        .data_in                (chacha_data_in),
        .data_out               (chacha_data_out),
        .data_out_valid         (chacha_data_out_valid)
        );
    
    chunk_divider chunk_div(
        .chunk_div_clk          (axis_clk),
        .chunk_div_reset        (~axis_reset_n),
        .chunk_div_valid        (chunk_div_valid),
        .encryp_decryp          (encryp_decryp),
        .m_axis_ready           (m_axis_ready),
        .public_key             (public_key_out),
        .nonce                  (nonce_out),
        .counter                (counter_out),
        .chunk_div_data_in      (chunk_div_data_in),
        .chunk_div_data_out     (chunk_div_data_out),
        .chunk_div_data_valid   (chunk_div_data_valid),
        .chunk_div_last_byte    (chunk_div_last_byte)
        );
    
    always @ (posedge axis_clk)
    begin
        if (~axis_reset_n) begin
            chacha_valid            <= 0;
            chacha_key              <= 0;
            chacha_data_in          <= 0;
            chacha_data_in_valid    <= 0;
            chacha_data_out_val     <= 0;
            chacha_nonce            <= 0;
            chacha_counter          <= 0;
            
            public_key_out          <= 0;
            nonce_out               <= 0;
            counter_out             <= 0;
            
            chunk_div_valid         <= 0;
            chunk_div_data_in       <= 0;
        end
        
        else begin
            case (encryp_decryp)
                ENCRYP: begin
                            if (chunk_int_data_valid) begin
                                chacha_data_in          <= chunk_int_data_out;
                                chacha_data_in_valid    <= 1;
                            end
                            
                            if (chacha_valid) begin
                                chacha_valid            <= 0;
                                chacha_data_out_val     <= 0;
                            end
                            else if (chacha_data_in_valid & crypto_data_valid) begin
                                chacha_key              <= {1'b0, crypto_data_out};
                                chacha_nonce            <= nonce_gen;
                                chacha_counter          <= counter_gen;
                                chacha_valid            <= 1;
                                chacha_data_in_valid    <= 0;
                            end
                            
                            if (chacha_data_out_valid & ~chacha_data_out_val) begin
                                chacha_data_out_val <= 1;
                                public_key_out      <= chacha_key;
                                nonce_out           <= chacha_nonce;
                                counter_out         <= chacha_counter;
                                chunk_div_data_in   <= chacha_data_out;
                                chunk_div_valid     <= 1;
                            end
                            else begin
                                chunk_div_valid     <= 0;
                            end
                        end
                DECRYP: begin
                            if (chacha_valid) begin
                                chacha_valid            <= 0;
                                chacha_data_out_val     <= 0;
                            end
                            else if (chunk_int_data_valid) begin
                                chacha_key              <= public_key_received;
                                chacha_nonce            <= chacha_nonce_received;
                                chacha_counter          <= chacha_counter_received;
                                chacha_data_in          <= chunk_int_data_out;
                                chacha_valid            <= 1;
                            end
                            
                            if (chacha_data_out_valid & ~chacha_data_out_val) begin
                                chacha_data_out_val <= 1;
                                chunk_div_data_in   <= chacha_data_out;
                                chunk_div_valid     <= 1;
                            end
                            else begin
                                chunk_div_valid     <= 0;
                            end
                        end
            endcase
        end
    end

    always @(posedge axis_clk)
    begin
        if (~axis_reset_n) begin
            session_id      <= 32'd0;
            nonce_gen       <= 64'd0;
            block_counter   <= 32'd0;
        end
        else begin
            if (chunk_int_data_valid) begin
                session_id      <= session_id + 1;
                block_counter   <= 32'd0;
            end
            else begin
                block_counter   <= block_counter + 1;
            end
    
            nonce_gen   <= {session_id, block_counter};
        end
    end
    
    always @ (posedge axis_clk)
    begin
        if (~axis_reset_n) begin
            counter_gen <= 0;
        end
        else if (chunk_div_valid) begin
            counter_gen <= counter_gen + 1;
        end
    end
    
    always @ (posedge axis_clk)
    begin
        if (~axis_reset_n) begin
            m_axis_valid    <= 0;
            m_axis_last     <= 0;
            m_axis_data     <= 0;
        end
        
        else begin
            m_axis_valid    <= chunk_div_data_valid;
            m_axis_last     <= chunk_div_last_byte;
            m_axis_data     <= chunk_div_data_out;
        end
    end
endmodule
