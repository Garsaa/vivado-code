module top(
    input logic clk,
    input logic [15:0] switchs, 
    // 0-3 carros-horizontal, 4-7 pedrestes-horizontal
    // 8-11 carros vertical, 12-15 pedrestes vertical
    output logic led_r,
    output logic led_g,
    output logic led_b,
    output logic vertical_led_b,
    output logic vertical_led_g,
    output logic vertical_led_r,
    output logic [15:0] led
);
    logic clk1hz;
    logic [1:0] led_color;
    logic [1:0] vertical_led_color;

    clkdiv #( .DIV(100000000) ) div1hz (
        .clk(clk),
        .tick(clk1hz)
    );

    fsm_game fsm_inst (
        .clk(clk1hz),
        .switchs(switchs),
        .led_color(led_color),
        .vertical_led_color(vertical_led_color)
    );

    leds_controller leds_inst (
        .switchs(switchs),
        .led(led)
    );

    led_rgb_controller led_inst (
        .led_color(led_color),
        .led_r(led_r),
        .led_g(led_g),
        .led_b(led_b)
    );

    led_rgb_controller second_led_inst (
        .led_color(vertical_led_color),
        .led_r(vertical_led_r),
        .led_g(vertical_led_g),
        .led_b(vertical_led_b)
    );

endmodule
