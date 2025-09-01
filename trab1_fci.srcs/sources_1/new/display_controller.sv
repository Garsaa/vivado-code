module display_controller (
    input  logic [3:0] BCD,     // 1 dígito em BCD
    output logic [6:0] seg,     // segmentos {a,b,c,d,e,f,g}
    output logic [7:0] an       // seleção do único dígito
);

    // Decodifica o valor BCD para 7 segmentos
    seg_7_enum decoder_i (
        .value(BCD),
        .seg(seg)
    );

    assign an = 8'b11111110; // ativa o ânodo 0

endmodule
