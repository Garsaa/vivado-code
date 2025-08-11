module fsm_game(
    input logic clk,
    output logic [1:0] led_color,
);

    typedef enum logic [2:0] { START, RED_LED, GREEN_LED, YELLOW_LED } state_t;
    state_t state = START;

    logic [31:0] count = 0;
    logic [31:0] count_2 = 0;
    logic [31:0] count_3 = 0;
    logic tick = 0;
    logic tick_2 = 0;
    logic tick_3 = 0;

    always_ff @(posedge clk) begin
            case (state)
                START: begin
                    led_color <= 2'b00;
                    state <= RED_LED;
                end
                RED_LED: begin
                    led_color <= 2'b11;
                    state <= GREEN_LED;
                end
                GREEN_LED: begin
                    led_color <= 2'b10;
                    state <= YELLOW_LED;
                end
                YELLOW_LED: begin
                    led_color <= 2'b01;
                    state <= RED_LED;
                end
                default: state <= START;
            endcase
    end


endmodule
