module adt7420_driver #(
    parameter bit [6:0] I2C_ADDR = 7'h4B, // endereço 7-bit típico na Nexys4 DDR
    parameter int       SAMPLE_DIV = 10_000 // nº de ticks entre leituras (~100ms se tick=1kHz)
)(
    input  logic clk,
    input  logic tick_i2c,   // base de tempo do I2C (cada tick = meio passo simples)

    // open-drain control (ligar no top aos pinos inout)
    input  logic scl_in,
    input  logic sda_in,
    output logic scl_oen,    // 1 = solta(Z) → puxa para 1 via pull-up; 0 = força 0
    output logic sda_oen,

    input  logic sample_en,  // 1 = faz leituras periódicas
    output logic signed [15:0] temp_q8_4,
    output logic new_sample
);
    // ------------------------
    // temporização de amostra
    // ------------------------
    logic [$clog2(SAMPLE_DIV):0] sample_cnt;
    logic                        fire;

    always_ff @(posedge clk) begin
        if (sample_en) begin
            if (sample_cnt == SAMPLE_DIV-1) begin
                sample_cnt <= '0;
                fire       <= 1'b1;
            end else begin
                sample_cnt <= sample_cnt + 1;
                fire       <= 1'b0;
            end
        end else begin
            sample_cnt <= '0;
            fire       <= 1'b0;
        end
    end


    typedef enum logic [3:0] {
        IDLE,
        START_A, START_B,
        SEND_BIT, GET_ACK,
        RESTART_A, RESTART_B,
        READ_BIT, SEND_ACK, SEND_NACK,
        STOP_A, STOP_B,
        DONE
    } i2c_phase_t;

    typedef enum logic [3:0] {
        SEQ_IDLE,
        SET_PTR,             // write: SLA+W, 0x00
        SET_PTR_SLAW, SET_PTR_REG, SET_PTR_STOP,
        READ_DATA,           // read: SLA+R, 2 bytes
        READ_SLAR, READ_MSB, ACK_MSB, READ_LSB, NACK_LSB, READ_STOP
    } seq_t;

    i2c_phase_t phase;
    seq_t       seq;
    logic [7:0] shifter_tx, shifter_rx;
    logic [2:0] bitcnt;

    // dados lidos
    logic [7:0] msb, lsb;

    // defaults
    always_comb begin
        new_sample = 1'b0;
    end

    // linha em idle = ‘1’ (solta, Z)
    // scl_oen/sda_oen: 1 = Z; 0 = força 0
    // Estados de fase alternam em cada tick_i2c para dar set/hold simples.
    always_ff @(posedge clk) begin
        scl_oen   <= 1'b1; // high (Z → pull-up)
        sda_oen   <= 1'b1;
        phase     <= IDLE;
        seq       <= SEQ_IDLE;
        bitcnt    <= 3'd7;
        shifter_tx<= 8'h00;
        msb       <= 8'h00;
        lsb       <= 8'h00;
        temp_q8_4 <= '0;
    end else if (tick_i2c) begin
        unique case (phase)
            IDLE: begin
                scl_oen <= 1'b1; sda_oen <= 1'b1; // ambos high
                if (fire && seq==SEQ_IDLE) begin
                    seq   <= SET_PTR;
                    phase <= START_A;
                end else if (seq != SEQ_IDLE) begin
                    phase <= START_A;
                end
            end

            // -------- START condition: SDA:1->0 enquanto SCL=1
            START_A: begin
                sda_oen <= 1'b0; // força 0 com SCL=1
                phase   <= START_B;
            end
            START_B: begin
                scl_oen <= 1'b0; // baixa clock
                // decide próximo passo da sequência
                unique case (seq)
                    SET_PTR: begin
                        shifter_tx <= {I2C_ADDR, 1'b0}; // SLA+W
                        bitcnt     <= 3'd7;
                        seq        <= SET_PTR_SLAW;
                        phase      <= SEND_BIT;
                    end
                    READ_DATA: begin
                        shifter_tx <= {I2C_ADDR, 1'b1}; // SLA+R
                        bitcnt     <= 3'd7;
                        seq        <= READ_SLAR;
                        phase      <= SEND_BIT;
                    end
                    default: phase <= IDLE;
                endcase
            end

            // -------- Envio de bits (SCL low → coloca SDA; SCL high → valida)
            SEND_BIT: begin
                // coloca bit em SDA enquanto SCL baixo
                sda_oen <= shifter_tx[7] ? 1'b1 : 1'b0; // 1->Z, 0->0
                // sobe clock
                scl_oen <= 1'b1;
                phase   <= GET_ACK; // usamos GET_ACK tanto p/ clock high quanto p/ ack depois
            end

            GET_ACK: begin
                // cai clock
                scl_oen <= 1'b0;
                // shift pro próximo
                shifter_tx <= {shifter_tx[6:0],1'b0};
                if (bitcnt != 0) begin
                    bitcnt <= bitcnt - 1;
                    phase  <= SEND_BIT;
                end else begin
                    // terminou 8 bits → agora ciclo de ACK do escravo (SDA solto)
                    sda_oen <= 1'b1; // solta SDA para escravo responder 0
                    // sobe clock para amostrar ACK
                    scl_oen <= 1'b1;
                    // cai clock e decide próximo estado da sequência
                    scl_oen <= 1'b0;
                    unique case (seq)
                        SET_PTR_SLAW: begin
                            shifter_tx <= 8'h00; // registrador 0x00 (pointer)
                            bitcnt     <= 3'd7;
                            seq        <= SET_PTR_REG;
                            phase      <= SEND_BIT;
                        end
                        SET_PTR_REG: begin
                            // STOP e depois iniciar leitura
                            seq   <= SET_PTR_STOP;
                            phase <= STOP_A;
                        end
                        READ_SLAR: begin
                            // próximo: ler MSB
                            bitcnt <= 3'd7; shifter_rx <= 8'h00;
                            phase  <= READ_BIT;
                            seq    <= READ_MSB;
                        end
                        default: phase <= IDLE;
                    endcase
                end
            end

            // -------- Leitura de um byte
            READ_BIT: begin
                // SDA é do escravo: mantenha solto
                sda_oen <= 1'b1;
                // sobe clock e amostra bit
                scl_oen <= 1'b1;
                shifter_rx <= {shifter_rx[6:0], sda_in};
                // cai clock
                scl_oen <= 1'b0;
                if (bitcnt != 0) begin
                    bitcnt <= bitcnt - 1;
                    phase  <= READ_BIT;
                end else begin
                    // terminou 8 bits → salvar e mandar ACK/NACK
                    unique case (seq)
                        READ_MSB: begin
                            msb   <= shifter_rx;
                            phase <= SEND_ACK;
                        end
                        READ_LSB: begin
                            lsb   <= shifter_rx;
                            phase <= SEND_NACK;
                        end
                        default: phase <= IDLE;
                    endcase
                end
            end

            // -------- ACK do mestre após ler MSB
            SEND_ACK: begin
                // ACK = mestre puxa SDA=0 durante 9º pulso
                sda_oen <= 1'b0;     // força 0
                scl_oen <= 1'b1;     // sobe clock
                scl_oen <= 1'b0;     // cai clock
                sda_oen <= 1'b1;     // solta
                // preparar para ler LSB
                bitcnt  <= 3'd7; shifter_rx <= 8'h00;
                phase   <= READ_BIT;
                seq     <= READ_LSB;
            end

            // -------- NACK do mestre após ler LSB
            SEND_NACK: begin
                // NACK = mestre deixa SDA=1 (solto) no 9º pulso
                sda_oen <= 1'b1;
                scl_oen <= 1'b1;     // sobe clock
                scl_oen <= 1'b0;     // cai clock
                // STOP
                seq     <= READ_STOP;
                phase   <= STOP_A;
            end

            // -------- STOP condition: SDA:0->1 enquanto SCL=1
            STOP_A: begin
                sda_oen <= 1'b0; // garante SDA=0
                scl_oen <= 1'b1; // SCL alto
                phase   <= STOP_B;
            end
            STOP_B: begin
                sda_oen <= 1'b1; // solta SDA → STOP (0->1 enquanto SCL=1)
                // decide sequência
                unique case (seq)
                    SET_PTR_STOP: begin
                        // repetir com leitura
                        seq   <= READ_DATA;
                        phase <= START_A;
                    end
                    READ_STOP: begin
                        // conversão p/ Q8.4 (modo 13-bit: >>3)
                        logic signed [15:0] raw16;
                        raw16     = {msb, lsb};
                        temp_q8_4 <= $signed(raw16) >>> 3; // 0.0625°C *16 = 1 LSB
                        new_sample<= 1'b1;
                        seq       <= SEQ_IDLE;
                        phase     <= DONE;
                    end
                    default: begin
                        seq   <= SEQ_IDLE;
                        phase <= DONE;
                    end
                endcase
            end

            DONE: begin
                // volta pra idle até próximo "fire"
                phase <= IDLE;
            end

            default: phase <= IDLE;
        endcase
    end

endmodule
