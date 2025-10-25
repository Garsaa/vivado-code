module temp_to_bcd #(
    parameter int NDIG = 4
)(
    input  logic signed [15:0] temp_q8_4,   // °C * 16
    output logic [NDIG*4-1:0]  digits_bcd,  // D[NDIG-1]..D0
    output logic [NDIG-1:0]    dp_mask      // liga ponto no dígito 1 (XX.X)
);
    // Arredonda para décimos: (val * 10) / 16  ≈  val*10 >> 4
    // round: add 8 antes do shift para aproximar
    logic signed [20:0] tenths; // cabe multiplicação
    logic signed [15:0] abs_tenths;
    logic        neg;

    always_comb begin
        logic signed [20:0] tmp = temp_q8_4;
        tmp      = tmp * 10;
        tmp      = (tmp >= 0) ? (tmp + 8) : (tmp - 8); // round toward nearest
        tenths   = tmp >>> 4; // °C * 10
        neg      = (tenths < 0);
        abs_tenths = neg ? -tenths[15:0] : tenths[15:0];
    end

    // separa XX.X (centenas/dezenas/unidades/décimos)
    logic [3:0] d_th, d_un, d_dez, d_cen;
    always_comb begin
        // limite simples (não mostra >99.9 correto), ajuste conforme necessidade
        int v = abs_tenths;
        d_th  = v % 10;  v = v / 10;   // décimos
        d_un  = v % 10;  v = v / 10;   // unidades
        d_dez = v % 10;  v = v / 10;   // dezenas
        d_cen = v % 10;                // centenas (não usado aqui)

        // Layout D3 D2 D1 D0 = [dezenas][unidades][décimos][(opção: sinal)]
        // Vou exibir: D3=DZ, D2=UN, D1=DECI, D0=‘-’ (se neg) ou espaço
        logic [3:0] d0 = neg ? 4'hA : 4'hF; // 0xA = traço “-” (defina no decoder se quiser), 0xF apagado
        digits_bcd = { d_dez, d_un, d_th, d0 };

        // ponto decimal entre D2 e D1 → acende no dígito D1 (índice 1)
        dp_mask = '0;
        dp_mask[1] = 1'b1;
    end
endmodule
