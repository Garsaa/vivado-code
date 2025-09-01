module fsm_game(
    input logic clk,
    input  logic [15:0] switchs,
    // 0-3 carros-horizontal, 4-7 pedrestes-horizontal
    // 8-11 carros vertical, 12-15 pedrestes vertical
    output logic [1:0] led_color,
    output logic [1:0] vertical_led_color
);
typedef enum logic [3:0] {
        START,
        GREEN_RED,
        YELLOW_RED,
        RED_GREEN,
        RED_YELLOW
    } state_t;
    state_t state = START;

    always_ff @(posedge clk) begin
            unique case (state)
               START: begin
                    led_color <= 2'b00;
                    vertical_led_color <= 2'b00;
                    state <= GREEN_RED;
                end
               GREEN_RED: begin
                    led_color <= 2'b10; 
                    vertical_led_color <= 2'b11; 
                    state <= YELLOW_RED;
                end
               YELLOW_RED: begin
                    led_color <= 2'b01;
                    vertical_led_color <= 2'b11;
                    state <= RED_GREEN;
                end
                RED_GREEN: begin
                    led_color <= 2'b11;
                    vertical_led_color <= 2'b10;
                    state <= RED_YELLOW;
                end
                RED_YELLOW: begin
                    led_color <= 2'b11;
                    vertical_led_color <= 2'b01;
                    state <= GREEN_RED;
                end
                default: state <= START;
            endcase
    end
endmodule
