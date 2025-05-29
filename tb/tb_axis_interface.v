`timescale 1ns / 1ps

module tb_axis_interface;
    reg axis_clk, axis_reset_n, encryp_decryp;
    reg s_axis_valid, m_axis_ready;
    reg [31:0] s_axis_data;
    wire [31:0] m_axis_data;
    wire s_axis_ready;
    wire m_axis_valid;
    wire m_axis_last;
    
    axis_interface dut(
        .axis_clk       (axis_clk),
        .axis_reset_n   (axis_reset_n),
        .encryp_decryp  (encryp_decryp),
        .s_axis_valid   (s_axis_valid),
        .m_axis_ready   (m_axis_ready),
        .s_axis_data    (s_axis_data),
        .m_axis_data    (m_axis_data),
        .s_axis_ready   (s_axis_ready),
        .m_axis_valid   (m_axis_valid),
        .m_axis_last    (m_axis_last)
        );
    
    reg [7:0]   count;
    reg [255:0] public_key;
    reg [63:0]  nonce;
    reg [63:0]  counter;
    reg [511:0] ciphertext;
    reg [511:0] plaintext;
    reg [511:0] plaintext_out;
    
    integer i;
    
    // TEST 1
    initial
    begin
        //$monitor("Slave Data Out = %h", m_axis_data);
        
        axis_clk = 0; axis_reset_n = 0;
        m_axis_ready = 0;
        count = 16;
        encryp_decryp = 0;
        s_axis_data = 0;
        s_axis_valid = 0;
        plaintext = 512'h5f3e3def40b2ff440f207194b2a7eb11b679504337d5b3f1974a479bc2eba0201ebae39bcbaab7bae9ad1b77803415fe0040bfc31e9c4b40ef902920ae5b08af;
        //plaintext = 512'h0;
        #50;
        
        axis_reset_n = 1;
        #1000;
        
        wait(s_axis_ready);
        #50;
        
        repeat(16) @(posedge axis_clk) begin
            s_axis_valid = 1;
            s_axis_data  = plaintext[count*32 - 1 -:32];
            if (count != 1)
                count = count - 1;
            else
                count = 8;
        end
        @(posedge axis_clk);
        s_axis_valid = 0;
        $display("======================================================================================================================================================");
        $display("Plaintext sent      = %h", plaintext);
        $display("======================================================================================================================================================");
        
        m_axis_ready = 1;
        
        @(posedge m_axis_valid);
        repeat(8) @ (posedge axis_clk) begin
            public_key[count*32 - 1 -: 32] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 2;
        end
        $display("Public Key = %h", public_key);
        repeat(2) @ (posedge axis_clk) begin
            nonce[count*32 - 1 -: 32] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 2;
        end
        $display("Nonce = %h", nonce);
        repeat(2) @ (posedge axis_clk) begin
            counter[count*32 - 1 -: 32] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 16;
        end
        $display("Counter = %h", counter);
        repeat(16) @ (posedge axis_clk) begin
            ciphertext[count*32 - 1 -: 32] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 8;
        end
        $display("======================================================================================================================================================");
        $display("Ciphertext received = %h", ciphertext);
        $display("======================================================================================================================================================");
        #50;
        m_axis_ready = 0;
        #100;
        
        encryp_decryp = 1;
        #1000;
        
        wait(s_axis_ready);
        #10;
        
        repeat(8) @(posedge axis_clk) begin
            s_axis_data = public_key[count*32 - 1 -: 32];
            s_axis_valid = 1;
            if (count != 1)
                count = count - 1;
            else
                count = 2;
        end
        repeat(2) @(posedge axis_clk) begin
            s_axis_data = nonce[count*32 - 1 -: 32];
            s_axis_valid = 1;
            if (count != 1)
                count = count - 1;
            else
                count = 2;
        end
        repeat(2) @(posedge axis_clk) begin
            s_axis_data = counter[count*32 - 1 -: 32];
            s_axis_valid = 1;
            if (count != 1)
                count = count - 1;
            else
                count = 16;
        end
        repeat(16) @(posedge axis_clk) begin
            s_axis_data = ciphertext[count*32 - 1 -: 32];
            s_axis_valid = 1;
            if (count != 1)
                count = count - 1;
            else
                count = 16;
        end
        @(posedge axis_clk);
        s_axis_valid = 0;
        
        m_axis_ready = 1;
        #10;
        
        @(posedge m_axis_valid);
        repeat(16) @ (posedge axis_clk) begin
            plaintext_out[count*32 - 1 -: 32] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 8;
        end
        $display("======================================================================================================================================================");
        $display("Plaintext received  = %h", plaintext_out);
        $display("======================================================================================================================================================");
        
        if (plaintext_out == plaintext) begin
            $display("Test Passed");
        end
        else begin
            $display("Test Failed");
        end
        #50;
        $finish;
    end
    
    // TEST 2
    /*initial
    begin
        axis_clk = 0; axis_reset_n = 0;
        count = 64;
        encryp_decryp = 0;
        plaintext = 512'h5f3e3def40b2ff440f207194b2a7eb11b679504337d5b3f1974a479bc2eba0201ebae39bcbaab7bae9ad1b77803415fe0040bfc31e9c4b40ef902920ae5b08af;
        //plaintext = 512'h0;
        #50;
        
        axis_reset_n = 1;
        #1000;
        
        m_axis_ready = 1;
        #50;
        
        repeat(64) @(posedge axis_clk) begin
            s_axis_valid = 1;
            s_axis_data  = plaintext[count*8 - 1 -:8];
            if (count != 1)
                count = count - 1;
            else
                count = 32;
        end
        @(posedge axis_clk);
        $display("=========================================================================================================================================");
        $display("Plaintext sent = %h", plaintext);
        $display("=========================================================================================================================================");
        s_axis_valid = 0;
        
        @(posedge m_axis_valid);
        repeat(32) @ (posedge axis_clk) begin
            public_key[count*8 - 1 -: 8] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 8;
        end
        $display("Public Key = %h", public_key);
        repeat(8) @ (posedge axis_clk) begin
            nonce[count*8 - 1 -: 8] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 8;
        end
        $display("Nonce = %h", nonce);
        repeat(8) @ (posedge axis_clk) begin
            counter[count*8 - 1 -: 8] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 64;
        end
        $display("Counter = %h", counter);
        repeat(64) @ (posedge axis_clk) begin
            ciphertext[count*8 - 1 -: 8] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 64;
        end
        $display("=========================================================================================================================================");
        $display("Ciphertext = %h", ciphertext);
        $display("=========================================================================================================================================");
        #50;
        
        #100;
        repeat(64) @(posedge axis_clk) begin
            s_axis_valid = 1;
            s_axis_data  = plaintext[count*8 - 1 -:8];
            if (count != 1)
                count = count - 1;
            else
                count = 32;
        end
        @(posedge axis_clk);
        $display("=========================================================================================================================================");
        $display("Plaintext sent = %h", plaintext);
        $display("=========================================================================================================================================");
        s_axis_valid = 0;
        
        @(posedge m_axis_valid);
        repeat(32) @ (posedge axis_clk) begin
            public_key[count*8 - 1 -: 8] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 8;
        end
        $display("Public Key = %h", public_key);
        repeat(8) @ (posedge axis_clk) begin
            nonce[count*8 - 1 -: 8] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 8;
        end
        $display("Nonce = %h", nonce);
        repeat(8) @ (posedge axis_clk) begin
            counter[count*8 - 1 -: 8] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 64;
        end
        $display("Counter = %h", counter);
        repeat(64) @ (posedge axis_clk) begin
            ciphertext[count*8 - 1 -: 8] = m_axis_data;
            if (count != 1)
                count = count - 1;
            else
                count = 32;
        end
        $display("=========================================================================================================================================");
        $display("Ciphertext = %h", ciphertext);
        $display("=========================================================================================================================================");
        #50;
        m_axis_ready = 0;
        #100;
        
        $finish;
    end*/
    always #5 axis_clk = ~axis_clk;
endmodule
