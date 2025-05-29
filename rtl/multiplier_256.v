`timescale 1ns / 1ps

module multiplier_256(
    // INPUT
    input wire clk,
    input wire reset,
    input wire start,
    input wire [255:0] in1,
    input wire [255:0] in2,
    
    // OUTPUT
    output reg [511:0] out,
    output reg done
    );
    
    reg [255:0] temp_reg1;
    reg [255:0] temp_reg2;

    reg  [2:0]   state;
    reg  [15:0]  mux;
    reg  [511:0] result [0:15];
    
    reg  [4:0]  count;
    reg  [31:0] out_par1 [0:7];
    reg  [47:0] out_par2 [0:7];
    
    reg  dsp_state;
    
    reg  acc1_state;
    reg  [47:0] acc1_result1 [0:3];
    reg  [79:0] acc1_result2 [0:3];
    
    reg  acc2_state;
    reg  [79:0]  acc2_result1 [0:1];
    reg  [143:0] acc2_result2 [0:1];
    
    reg  acc3_state;
    reg  [143:0] acc3_result1;
    reg  [271:0] acc3_result2;
    
    reg  acc4_state;
    reg  [511:0] acc4_result;

    always @ (posedge clk)
    begin
        if (reset) begin
            dsp_state   <= 0;
        end
        else begin
            case (dsp_state)
                0 : begin 
                        if (start) begin
                           dsp_state    <= 1; 
                        end
                    end
                1 : begin
                        if (count > 15) begin
                            dsp_state  <= 0;
                        end
                        else begin
                            out_par1[0]   <= temp_reg1[15:0]    * mux;
                            out_par2[0]   <= temp_reg1[31:16]   * mux;
                            out_par1[1]   <= temp_reg1[47:32]   * mux;
                            out_par2[1]   <= temp_reg1[63:48]   * mux;
                            out_par1[2]   <= temp_reg1[79:64]   * mux;
                            out_par2[2]   <= temp_reg1[95:80]   * mux;
                            out_par1[3]   <= temp_reg1[111:96]  * mux;
                            out_par2[3]   <= temp_reg1[127:112] * mux;
                            out_par1[4]   <= temp_reg1[143:128] * mux;
                            out_par2[4]   <= temp_reg1[159:144] * mux;
                            out_par1[5]   <= temp_reg1[175:160] * mux;
                            out_par2[5]   <= temp_reg1[191:176] * mux;
                            out_par1[6]   <= temp_reg1[207:192] * mux;
                            out_par2[6]   <= temp_reg1[223:208] * mux;
                            out_par1[7]   <= temp_reg1[239:224] * mux;
                            out_par2[7]   <= temp_reg1[255:240] * mux;
                        end
                    end
            endcase
        end
    end
    
    always @ (posedge clk)
    begin
        if (reset) begin
            acc1_state  <= 0;
        end
        else begin
            case (acc1_state)
                0 : begin
                        if (start) begin
                            acc1_state   <= 1;
                        end
                    end
                1 : begin
                        if (count > 16) begin
                            acc1_state  <= 0;
                        end
                        else if (count > 0) begin
                            acc1_result1[0] <= out_par1[0] + (out_par2[0] << 16);
                            acc1_result2[0] <= {32'b0, out_par1[1] + (out_par2[1] << 16)};
                            acc1_result1[1] <= out_par1[2] + (out_par2[2] << 16);
                            acc1_result2[1] <= {32'b0, out_par1[3] + (out_par2[3] << 16)};
                            acc1_result1[2] <= out_par1[4] + (out_par2[4] << 16);
                            acc1_result2[2] <= {32'b0, out_par1[5] + (out_par2[5] << 16)};
                            acc1_result1[3] <= out_par1[6] + (out_par2[6] << 16);
                            acc1_result2[3] <= {32'b0, out_par1[7] + (out_par2[7] << 16)};
                        end
                    end
            endcase
        end
    end
    
    always @ (posedge clk)
    begin
        if (reset) begin
            acc2_state  <= 0;
        end
        else begin
            case (acc2_state)
                0 : begin
                        if (start) begin
                            acc2_state  <= 1;
                        end
                    end
                1 : begin
                        if (count > 17) begin
                            acc2_state  <= 0;
                        end
                        else if (count > 1) begin
                            acc2_result1[0] <= acc1_result1[0] + (acc1_result2[0] << 32);
                            acc2_result2[0] <= {64'b0, acc1_result1[1] + (acc1_result2[1] << 32)};
                            acc2_result1[1] <= acc1_result1[2] + (acc1_result2[2] << 32);
                            acc2_result2[1] <= {64'b0, acc1_result1[3] + (acc1_result2[3] << 32)};
                        end
                    end
            endcase
        end
    end
    
    always @ (posedge clk)
    begin
        if (reset) begin
            acc3_state  <= 0;
        end
        else begin
            case (acc3_state)
                0 : begin
                        if (start) begin
                            acc3_state  <= 1;
                        end
                    end
                1 : begin
                        if (count > 18) begin
                            acc3_state  <= 0;
                        end
                        else if (count > 2) begin
                            acc3_result1    <= acc2_result1[0] + (acc2_result2[0] << 64);
                            acc3_result2    <= {128'b0, acc2_result1[1] + (acc2_result2[1] << 64)};
                        end
                    end
            endcase
        end
    end
    
    always @ (posedge clk)
    begin
        if (reset) begin
            acc4_state  <= 0;
        end
        else begin
            case (acc4_state)
                0 : begin
                        if (start) begin
                            acc4_state  <= 1;
                        end
                    end
                1 : begin
                        if (count > 19) begin
                            acc4_state  <= 0;
                        end
                        else  if (count > 3) begin
                            acc4_result <= {(acc3_result1 + (acc3_result2 << 128)), 240'h0};
                        end
                    end
            endcase
        end
    end
     
    always @*
    begin
        mux = 0;
        case (count)
            0 : begin
                    mux = temp_reg2[15:0];
                end
            1 : begin
                    mux = temp_reg2[31:16];
                end
            2 : begin
                    mux = temp_reg2[47:32];
                end
            3 : begin
                    mux = temp_reg2[63:48];
                end
            4 : begin
                    mux = temp_reg2[79:64];
                end
            5 : begin
                    mux = temp_reg2[95:80];
                end
            6 : begin
                    mux = temp_reg2[111:96];
                end
            7 : begin
                    mux = temp_reg2[127:112];
                end
            8 : begin
                    mux = temp_reg2[143:128];
                end
            9 : begin
                    mux = temp_reg2[159:144];
                end
           10 : begin
                    mux = temp_reg2[175:160];
                end
           11 : begin
                    mux = temp_reg2[191:176];
                end
           12 : begin
                    mux = temp_reg2[207:192];
                end
           13 : begin
                    mux = temp_reg2[223:208];
                end
           14 : begin
                    mux = temp_reg2[239:224];
                end
           15 : begin
                    mux = temp_reg2[255:240];
                end
           default : ;
        endcase
    end

    always @ (posedge clk)
    begin
        if (reset) begin
            state       <= 0;
            temp_reg1   <= 0;
            temp_reg2   <= 0;
            
            count       <= 21;
            out         <= 0;
            done        <= 0;
        end
        else begin
            case (state)
                0 : begin
                        done    <= 0;
                        if (start) begin
                            temp_reg1   <= in1;
                            temp_reg2   <= in2;
                            state       <= 1;
                            count       <= 0;
                        end
                    end
                1 : begin
                        if (count > 20) begin
                            out     <= result[15];
                            state   <= 2;
                        end
                        else begin
                            count   <= count + 1;
                        end
                    end
                2 : begin
                        done    <= 1;
                        state   <= 0;
                    end
            endcase
        end
    end
    
    always @ (posedge clk)
    begin
        if (count > 4 && count < 21) begin
            case (count)
                5 : result[0]   <= acc4_result;
                default : result[count-5]   <= (result[count-6] >> 16) + acc4_result;
            endcase
        end
    end

endmodule