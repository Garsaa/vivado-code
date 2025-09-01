module fsm_game(
    input logic clk,
    input  logic [15:0] switchs,
    output logic [1:0] led_color,
    output logic [1:0] vertical_led_color
);

    typedef enum logic [2:0] { START, RED_LED, GREEN_LED, YELLOW_LED, WAIT_TO_YELLOW } state_t;
    state_t state = START;

    logic [31:0] count = 0;
    logic [31:0] count_2 = 0;
    logic [31:0] count_3 = 0;

     always_ff @(posedge clk) begin
            unique case (state)
                START: begin
                    led_color <= 2'b00;
                    fsm_count_3 <= 4'd0;
                    state <= GREEN_LED;
                end
                GREEN_LED: begin
                    led_color <= 2'b10;
                    if(btnc) begin
                        count <= 0;
                        state <= WAIT_TO_YELLOW;
                    end
                end
                WAIT_TO_YELLOW: begin
                    if(count >= 3) begin
                        led_color <= 2'b01;
                        state <= YELLOW_LED;
                    end else begin
                        count <= count + 1;
                    end
                end
                YELLOW_LED: begin
                    led_color <= 2'b01;
                    if (count_2 >= 2) begin
                        count_3 <= 0;
                        fsm_count_3 <= 4'd5;
                        state   <= RED_LED;
                    end else begin
                        count_2 <= count_2 + 1;
                    end
                end
                RED_LED: begin
                    led_color <= 2'b11;
                    if (count_3 >= 5) begin
                        state <= GREEN_LED;
                    end else begin
                        count_3 <= count_3 + 1;
                        fsm_count_3 <= fsm_count_3 - 1;
                    end
                end
                default: state <= START;
            endcase
    end
endmodule
