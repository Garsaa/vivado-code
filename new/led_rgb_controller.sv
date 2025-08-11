module led_rgb_controller(
    input logic [1:0] led_color,
    output logic led_r,
    output logic led_g,
    output logic led_b
);

    always_comb begin
        case (led_color)
            2'b01: begin // Amarelo (R + G)
                led_r = 1;
                led_g = 1;
                led_b = 0;
            end
            2'b10: begin // Verde
                led_r = 0;
                led_g = 1;
                led_b = 0;
            end
            2'b11: begin // Vermelho
                led_r = 1;
                led_g = 0;
                led_b = 0;
            end
            default: begin // branco
                led_r = 1;
                led_g = 1;
                led_b = 1;
            end
        endcase
    end

endmodule
