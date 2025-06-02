`timescale 1ns / 1ps

module private_key_gen(
    // INPUT
    input wire key_clk,
    input wire key_reset,
    
    // OUTPUT
    output reg [255:0] private_key,
    output reg         private_key_valid
    );
    
    reg [5:0]  key_index;
    reg        next_key;
    
    reg        key_state;
    reg [25:0] key_count;
    
    always @ (posedge key_clk)
    begin
        if (key_reset) begin
            next_key    <= 1;
            key_index   <= 0;
            key_state   <= 0;
            key_count   <= 0;
        end
        else begin
            case (key_state)
                0 : begin
                        next_key    <= 0;
                    
                        if (key_count == 26'h3ffffff) begin
                            key_count   <= 0;
                            key_state   <= 1;
                        end
                        else begin
                            key_count   <= key_count + 1;
                        end
                    end
                1 : begin
                        next_key    <= 1;
                        key_index   <= key_index + 1;
                        key_state   <= 0;
                    end
            endcase
        end
    end
    
    always @ (posedge key_clk)
    begin
        if (key_reset) begin
            private_key <= 0;
            private_key_valid   <= 0;
        end
        else begin
            if (next_key) begin
                private_key_valid   <= 1;
            
            case (key_index)
                0 : private_key <= 256'hebcdf67adb1b17d84f7844223fa488fa46371abb42f2afc08b68f0a9a71a859f;
                1 : private_key <= 256'h68b66a7d984f9bbdba82121b40706c25b43692825a9c5fcaf7826c98cbea4e71;
                2 : private_key <= 256'hd0a339d12e292d5b39b1a2b35fc1d069679fae07bf0b5a15096907479b23d945;
                3 : private_key <= 256'h00d0d7a9aa631a494388227f93aa35bc33c6150aa9267749ce38321c8db26e54;
                4 : private_key <= 256'h584505cd834f56c88b477173f44010fcec5ca3796ef357446f6568feaf98867e;
                5 : private_key <= 256'h4830d1797a9daa857c4afec27f20f9e9bad64022a848c18859af68da8ac96a69;
                6 : private_key <= 256'ha051c3dc660ff3a43c16763716706b190e07bee4336d93114200c76110aeee4f;
                7 : private_key <= 256'h20ae7bd1247ccec43afa6910649d25b5612f80a2f936bbbffe2c5c790b5eff67;
                8 : private_key <= 256'hf00501fcd157f9e12b8d8f7758a0297778c197d5fc13db950bc07f921d5cd077;
                9 : private_key <= 256'h7026651da85a27a65072152c208b7359a3631a1314430ff7a17cfc6dd466fb70;
               10 : private_key <= 256'h08da78f0bf60572c0b84e46df4380b0410f862d1bcc917b9f8b741e8a9343141;
               11 : private_key <= 256'h48debcad0a03044763798a3cefae1634fec0acf9aae4b52bf0c540c012facb69;
               12 : private_key <= 256'h40a92b9a84b02e6329ff67859076c83e11629302ac5f3112d3907860e5d2da57;
               13 : private_key <= 256'h183225143cbc009e578569e6c22fc19ac6b8e9da177b58dcb0b4e5a36180254e;
               14 : private_key <= 256'hb05341949d4d3aa232fa5578e4463fd1c84b6af4d4cb59f76c31c4dae55be346;
               15 : private_key <= 256'hf0b3f0c8dc5563d630025c96872ea1ec3cc3794b8bad2f09d7143c005bfd1849;
               16 : private_key <= 256'h30d0b82b334533a91562db208fc4cdb7870f70d06bfbcb4611b316dad625a063;
               17 : private_key <= 256'h3889a3c12b21f02f717e36a70fb51cc66f3b7ab83b17928c41b8dd94d96d8e7f;
               18 : private_key <= 256'h9091601d2206f3762db643311b329053fd64768decfb471dcd538477f6896361;
               19 : private_key <= 256'hc0c48ecc693ab781305ec521baee27d397a980f1e5f8fee67bb3970e73e5c15c;
               20 : private_key <= 256'h30c24e2ddb0ef1ab58b9c48b5d0bb2f8ade9ab687f1b550c2afba4a0f5f92f5f;
               21 : private_key <= 256'h20bffca46298f79d34c498476e9118fb6c86c14ba00476c94e6b1839745e1a50;
               22 : private_key <= 256'h582816f9a222d22eda2e6235470fcb80ece05405f3ba5412e84c0e9d36347670;
               23 : private_key <= 256'hb82519ae5b367596c25c53c563b20599a1c1b226a2a9c6e9fec421c217007152;
               24 : private_key <= 256'hd88d83ddc77203109c5ce7dd4d153ceb9998654b4ae692fda381d0fa07196d43;
               25 : private_key <= 256'h803f4d50b564378463fde9a86fb38763eeb1885df2126967ea526a5d181b624b;
               26 : private_key <= 256'hd0cfe22e699206459eb8e4a5d5aa4af6505b2cfeeafcb0e86a44d05f837d135a;
               27 : private_key <= 256'h70acfc2774a73fa531703c69cd34a19b519482d410984004dc31ca19d9401967;
               28 : private_key <= 256'h10855bf90d931c848f27f93ccc19ced019d2027f9408ff4b5d2461651d529246;
               29 : private_key <= 256'h903e48c69349637fc636a7d4c6d0c4d11ca33f5c2346b6e37b31978cc5e3ac76;
               30 : private_key <= 256'hc88280a4443908d7a62ca5f2108953152752645b972de18df79b72d5362c3072;
               31 : private_key <= 256'h68159f8821be9d6e74a2ae6c20acadd51d46558cac39d7b1f3028d634162f475;
               32 : private_key <= 256'h6059fb68eae983cbbb9e0f622606204672bb5df440e777c4ea66c1ad53813240;
               33 : private_key <= 256'h600bb6c642983ca93e4a5637f44bb9cdb90c80abeb91c9f574ac865c25966e55;
               34 : private_key <= 256'h00f4ce75d709046164e7948ec708db8838086bdfcbdf2c123db8bf0f751b8670;
               35 : private_key <= 256'h10dccf36a3e5791f7243f6403e6826a86a591ba16e31c0db7eb0ebd0e589c159;
               36 : private_key <= 256'he005c52cf5b997a8cfeeb078d579d6e904ed44e3c7ce73a04d7f100aeadbbc67;
               37 : private_key <= 256'hf09dc72c6123692c9900e99165a827ff8da0fcc8572f6828c3ea2d7b0167765a;
               38 : private_key <= 256'hb0045bbe6e7efdb5732e0a400b159d673ec259cde360fe8cf45feeea07ff7a5b;
               39 : private_key <= 256'h7840a9659403be9b111dc98cd70ee4defcaaf511d31836dbe58d7a8cbb551968;
               40 : private_key <= 256'hf018d6814d44e6eba357b83d273a7c6e1bcd34dbab515d4b57a3f5f5599ead6b;
               41 : private_key <= 256'h389b81e751851b32873cb8139ce9d45f592b98b1a90b3692c3706933a3a8e769;
               42 : private_key <= 256'hc8abea3395c97baca488a398a4eabbaaa80d1fbad03a8b515d48e43c53aff348;
               43 : private_key <= 256'h2036c98d389d2b3a3913e6e821fbb0400641dc71c264d6d50c0c901d4a616671;
               44 : private_key <= 256'h08b5e555297d2c380c741afb08c4fa1d3a8abd5ad0da4ddf629ad121fdb5936a;
               45 : private_key <= 256'h402334b96189276b0b6677e70101bdc2441600e7bee69d4ebcdb57ec63086369;
               46 : private_key <= 256'h50de852103f406292d0914f30d470bb05b8ac21a9b5d642938051deae07d4753;
               47 : private_key <= 256'h3838b676a70aff59e1a7847ff70478693db5c9d40938cb02d8f1f36e7500f756;
               48 : private_key <= 256'ha8feab0ffa81e11eb3e24af6edbacca7773b4665c8aa08777e390f8129b42479;
               49 : private_key <= 256'h1048cc2fbad97a741e9187abf6bb0b65db99174515be092824d564bd3207ba5d;
               50 : private_key <= 256'h70211ae4301221b261d768b01d9a00cb9155c9c0b644e3cc05b78da4ea93a84d;
               51 : private_key <= 256'h305f334f9aacbb7a15464c5ac64bffb4e48408ee11e4d6ae850f4596457b877b;
               52 : private_key <= 256'h78498ba22c61f20327adab476415a085c72599237604bf77a3c73ff5466a2e68;
               53 : private_key <= 256'h88dca9abb43227ccaf27c871c8aba3eb56bd73e1c61cabebf32dba9067bc6877;
               54 : private_key <= 256'hf0d4a335a8f615a8cad496c8fb5d8c35ecc72f9f44d837cd14d06b387c3b8872;
               55 : private_key <= 256'h789cf6447e4f088474153091f2aadb39b84bad3a4cbe31a62c2e71248c9a167b;
               56 : private_key <= 256'hd878b0a1767df62d67fb1d307939b2dcee9cb4166ad1faee3d549773deb44570;
               57 : private_key <= 256'ha056eca3f05b932882475942d7fdf77be7ebd7b8b015d017a434897520b2437a;
               58 : private_key <= 256'hb86be74e80174d5048f9eedec160fdcd243649c65ce46f6a4abf0001b4bd194f;
               59 : private_key <= 256'h60842599e720c4eca657db63e1587016490687f09114f085aafd7c02e2bfd242;
               60 : private_key <= 256'hd07f9c3eceb97b8e0ea39c843b92544fa9d416845f27aa704f1a0dc986c9de6e;
               61 : private_key <= 256'hb8296d6ebd52241f9e7cc667149f31b72c4cd6552f2203ca54b455cd50ca3457;
               62 : private_key <= 256'h5814f399da90c5bba5d40503bca98bddd40e8084267e0bd7dac95b0f45654563;
               63 : private_key <= 256'he8c0b7b1ea50ffdcb4d3acb7671ed3240651d138752dd648bab24ac61fa74367;
            endcase
            end
            else begin
                private_key_valid   <= 0;
            end
        end
    end
endmodule
