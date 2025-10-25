module top(
    input  logic       clk,        // clock principal de 100 MHz da Nexys 4 DDR
    inout  wire        TMP_SCL,    // pino físico SCL do I²C (open-drain: 0 ou Z)
    inout  wire        TMP_SDA,    // pino físico SDA do I²C (open-drain: 0 ou Z)
    output logic [6:0] seg,        // saídas dos segmentos a..g do display 7-seg
    output logic [7:0] an          // seleção de ânodos (8 dígitos multiplexados)
);

    // ===== Geração de tick para o display (≈1 kHz) =====
    logic tick_disp;               // pulso periódico para varrer os dígitos do 7-seg
    clkdiv #(.DIV(100000)) u_div_disp ( // 100 MHz / 100000 = 1 kHz
        .clk (clk),                // clock de entrada do divisor
        .tick(tick_disp)           // pulso de saída (1 ciclo) a cada 1 ms
    );

    // ===== Geração de tick para o I²C (≈100 kHz) =====
    logic tick_i2c;                // base de tempo para a FSM do I²C (SCL)
    clkdiv #(.DIV(1000)) u_div_i2c ( // 100 MHz / 1000 = 100 kHz
        .clk (clk),                // clock de entrada do divisor
        .tick(tick_i2c)            // pulso de saída (1 ciclo) a cada 10 µs
    );

    // ===== Amostragem das linhas I²C físicas =====
    wire  scl_in = TMP_SCL;        // leitura do nível atual de SCL no pino
    wire  sda_in = TMP_SDA;        // leitura do nível atual de SDA no pino

    // ===== Controles open-drain das linhas I²C =====
    logic scl_oen, sda_oen;        // 1 = solta (Z, vira ‘1’ via pull-up), 0 = força ‘0’

    assign TMP_SCL = scl_oen ? 1'bz : 1'b0; // modela saída open-drain em SCL
    assign TMP_SDA = sda_oen ? 1'bz : 1'b0; // modela saída open-drain em SDA

    // ===== Sinais de temperatura lida do sensor =====
    logic signed [15:0] temp_q8_4; // temperatura em Q8.4 (°C * 16) do ADT7420
    logic               new_sample;// pulso indicando “chegou nova amostra”

    // ===== Driver do ADT7420 (I²C) =====
    adt7420_driver #(
        .I2C_ADDR  (7'h4B),        // endereço I²C 7-bit do ADT7420 na Nexys4 DDR
        .SAMPLE_DIV(10_000)        // nº de ticks_i2c entre leituras (~100 ms)
    ) u_adt (
        .clk       (clk),          // clock do sistema
        .tick_i2c  (tick_i2c),     // base de tempo para gerar SCL/estados do I²C

        .scl_in    (scl_in),       // nível lido em SCL (pino)
        .sda_in    (sda_in),       // nível lido em SDA (pino)
        .scl_oen   (scl_oen),      // controle open-drain SCL: 1=Z, 0=0
        .sda_oen   (sda_oen),      // controle open-drain SDA: 1=Z, 0=0

        .sample_en (1'b1),         // habilita leituras periódicas
        .temp_q8_4 (temp_q8_4),    // saída: temperatura em Q8.4
        .new_sample(new_sample)    // saída: strobe de nova amostra
    );

    // ===== Conversão da temperatura para BCD + máscara do ponto decimal =====
    logic [15:0] digits_bcd;       // 4 dígitos BCD (D3..D0), 4 bits por dígito
    logic [3:0]  dp_mask;          // máscara do ponto decimal (1 liga o ponto no dígito)

    temp_to_bcd #(.NDIG(4)) u_fmt ( // formata “XX.X” (ex.: 25.3 °C)
        .temp_q8_4 (temp_q8_4),    // entrada: temperatura em Q8.4
        .digits_bcd(digits_bcd),   // saída: dígitos BCD para o display
        .dp_mask   (dp_mask)       // saída: quais dígitos acendem o ponto
    );

    // ===== Controlador do display 7-segmentos (multiplex) =====
    sevenseg_ctrl #(.NDIG(4)) u_disp ( // varre 4 dígitos a ~1 kHz
        .clk        (clk),         // clock de sistema
        .tick_disp  (tick_disp),   // tick de varredura (define taxa de multiplex)
        .digits_bcd (digits_bcd),  // dígitos a exibir (BCD)
        .dp_mask    (dp_mask),     // quais dígitos têm ponto decimal aceso
        .seg        (seg),         // saídas a..g dos segmentos
        .an         (an)           // seleção do dígito ativo (ânodos)
        // se existir pino físico do DP, poderia haver: .dp(dp)
    );

endmodule
