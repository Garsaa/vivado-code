module display_controller(
    input logic show_char,
    input logic [1:0] current_dir,
    input logic error,
    input logic clk,
    input logic win,
    output logic [6:0] seg,
    output logic [7:0] an
);

    logic [2:0] digit_index = 0;

    logic [6:0] seg_data[0:7];

    always_ff @(posedge clk) begin
        digit_index <= digit_index + 1;
    end

    // Seleciona qual display está ativo (1 ligado por vez, ativo baixo)
    always_comb begin
        an = ~(8'b00000001 << digit_index);
        seg = seg_data[digit_index];
    end

    // Define os caracteres a serem exibidos
    always_comb begin
        // Default: tudo apagado
        seg_data = '{default: 7'b1111111};

        if (error) begin
            seg_data[3] = 7'b0001110; // F
            seg_data[2] = 7'b0001000; // A
            seg_data[1] = 7'b1001111; // I
            seg_data[0] = 7'b1000111; // L
        end else if (win) begin
            seg_data[2] = 7'b0000001; // W
            seg_data[1] = 7'b1001111; // I
            seg_data[0] = 7'b0101011; // N
        end else if (show_char) begin
            case (current_dir)
                2'd0: begin // "UP"
                    seg_data[0] = 7'b0001100; // U
                    seg_data[1] = 7'b1000001; // P
                end
                2'd1: begin // "RIGHT"
                    seg_data[4] = 7'b0001010; // R
                    seg_data[3] = 7'b1001111; // I
                    seg_data[2] = 7'b0000010; // G
                    seg_data[1] = 7'b0001001; // H
                    seg_data[0] = 7'b1111000; // T
                end
                2'd2: begin // "DOWN"
                    seg_data[3] = 7'b0100001; // D
                    seg_data[2] = 7'b1000000; // O
                    seg_data[1] = 7'b0000001; // W
                    seg_data[0] = 7'b0101011; // N
                end
                2'd3: begin // "LEFT"
                    seg_data[3] = 7'b1000111; // L
                    seg_data[2] = 7'b0000110; // E
                    seg_data[1] = 7'b0001110; // F
                    seg_data[0] = 7'b1111000; // T
                end
                default: seg_data = '{default: 7'b1111111};
            endcase
        end
    end

endmodule
