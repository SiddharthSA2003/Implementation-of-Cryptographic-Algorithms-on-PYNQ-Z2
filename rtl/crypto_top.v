`timescale 1ns / 1ps

module crypto_top(
    // INPUT
    input wire          crypto_clk,
    input wire          crypto_reset,
    input wire          top_ready,
    
    // OUTPUT
    output reg [254:0]  crypto_data_out,
    output reg          crypto_data_valid
    );
    
    wire [255:0] private_key;
    wire         private_key_valid;
    
    wire [254:0] mont_data_Rx;
    wire [254:0] mont_data_Rz;
    wire         mont_data_valid;
    
    wire [254:0] inv_inverse;
    wire         inv_data_valid;
    
    wire [511:0] mul_out;
    wire         mul_data_valid;
    
    wire [254:0] mod_data_out;
    wire         mod_data_valid;
    
    private_key_gen key_top(
        .key_clk            (crypto_clk),
        .key_reset          (crypto_reset),
        .top_ready          (top_ready),
        .private_key        (private_key),
        .private_key_valid  (private_key_valid)
        );
    
    montgomery_ladder crypto_mont(
        .mont_clk           (crypto_clk),
        .mont_reset         (crypto_reset),
        .mont_valid         (private_key_valid),
        .mont_data_in       (private_key),
        .Rx                 (mont_data_Rx),
        .Rz                 (mont_data_Rz),
        .mont_data_valid    (mont_data_valid)
        );
    
    mod_inverse mod_inv(
        .inv_clk            (crypto_clk),
        .inv_reset          (crypto_reset),
        .inv_valid          (mont_data_valid),
        .inv_in             (mont_data_Rz),
        .inv_inverse        (inv_inverse),
        .inv_data_valid     (inv_data_valid)
        );
    
    multiplier_256 crypto_mult(
        .clk                (crypto_clk),
        .reset              (crypto_reset),
        .start              (inv_data_valid),
        .in1                ({1'b0, mont_data_Rx}),
        .in2                ({1'b0, inv_inverse}),
        .out                (mul_out),
        .done               (mul_data_valid)
        );
    
    serial_modulo crypto_modulo(
        .clk                (crypto_clk),
        .reset              (crypto_reset),
        .start              (mul_data_valid),
        .A                  (mul_out),
        .result             (mod_data_out),
        .done               (mod_data_valid)
        );
    
    always @ (posedge crypto_clk)
    begin
        if (crypto_reset) begin
            crypto_data_valid   <= 0;
            crypto_data_out     <= 0;
        end
        else begin
            if (private_key_valid) begin
                crypto_data_valid   <= 0;
            end
            else if (mod_data_valid) begin
                crypto_data_out     <= mod_data_out;
                crypto_data_valid   <= 1;
            end
        end
    end
endmodule
