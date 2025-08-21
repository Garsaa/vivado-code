module fsm_game(
    input logic clk,
    input logic switch,
    output logic [1:0] led_color,
    output logic [1:0] secondary_led_color
);

typedef enum logic [3:0] {
        START,
        GREEN_RED,
        YELLOW_RED,
        RED_GREEN,
        RED_YELLOW,
        BLINK_ON,
        BLINK_OFF
    } state_t;
    state_t state = START;

    always_ff @(posedge clk) begin
            unique case (state)
               START: begin
                    led_color <= 2'b00;
                    secondary_led_color <= 2'b00;
                    state <= GREEN_RED;
                end
               GREEN_RED: begin
                    if (switch) begin
                        state <= BLINK_ON;
                    end else begin
                        led_color <= 2'b10; 
                        secondary_led_color <= 2'b11; 
                        state <= YELLOW_RED;
                    end
                end
               YELLOW_RED: begin
                    if (switch) begin
                        state <= BLINK_ON;
                    end else begin
                        led_color <= 2'b01;
                        secondary_led_color <= 2'b11;
                    state <= RED_GREEN;
                    end
                end
                RED_GREEN: begin
                    if (switch) begin
                        state <= BLINK_ON;
                    end else begin
                        led_color <= 2'b11;
                        secondary_led_color <= 2'b10;
                        state <= RED_YELLOW;
                    end
                end
                RED_YELLOW: begin
                    if (switch) begin
                        state <= BLINK_ON;
                    end else begin
                        led_color <= 2'b11;
                        secondary_led_color <= 2'b01;
                        state <= GREEN_RED;
                    end
                end
             BLINK_ON: begin
                led_color <= 2'b01;
                secondary_led_color <= 2'b11;
                if (!switch) state <= GREEN_RED;
                else state <= BLINK_OFF;
            end
               BLINK_OFF: begin
                led_color <= 2'b00;
                secondary_led_color <= 2'b00;
                if (!switch) state <= GREEN_RED;
                else state <= BLINK_ON;
            end
                default: state <= START;
            endcase
    end


endmodule
