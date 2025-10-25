module sevenseg_ctrl #(
    parameter int NDIG = 4
)(
    input  logic                 clk,
    input  logic                 tick_disp,          // ~1–2 kHz
    input  logic [NDIG*4-1:0]    digits_bcd,         // nibbles D[NDIG-1]..D0
    input  logic [NDIG-1:0]      dp_mask,            // 1 = acende ponto do dígito
    output logic [6:0]           seg,
    output logic [7:0]           an                  // usa só NDIG LSBs
    // se tiver pino dp separado: output logic dp
);
    logic [$clog2(NDIG)-1:0] idx;
    logic [3:0] cur_bcd;

    // scan de dígitos
    always_ff @(posedge clk) if (tick_disp) idx <= (idx == NDIG-1) ? '0 : idx + 1'b1;

    // seleciona nibble atual
    always_comb begin
        cur_bcd = digits_bcd[idx*4 +: 4];
    end

    // decodificador
    seg_7_enum u_dec (.value(cur_bcd), .seg(seg));

    // ânodos ativos: assume ânodo ativo em 0 (Nexys 4 DDR)
    always_comb begin
        an = 8'hFF;
        an[idx] = 1'b0;
    end

    // Se tiver pino dp dedicado, descomente:
    // assign dp = ~dp_mask[idx]; // exemplo para dp ativo em 0
endmodule
