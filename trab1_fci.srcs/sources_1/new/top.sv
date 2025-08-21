module top(
    input logic clk,
    input logic switch,

    output logic led_r,
    output logic led_g,
    output logic led_b,
    output logic secondary_led_r,
    output logic secondary_led_g,
    output logic secondary_led_b
);

    logic clk1hz;
    logic [1:0] led_color;
    logic [1:0] secondary_led_color;


    clkdiv #( .DIV(100000000) ) div1hz (
        .clk(clk),
        .tick(div1hz)
    );

    fsm_game fsm_inst (
        .clk(clk1hz),
        .led_color(led_color),
        .secondary_led_color(secondary_led_color),
        .switch(switch)
    );

    led_rgb_controller led_inst (
        .led_color(led_color),
        .led_r(led_r),
        .led_g(led_g),
        .led_b(led_b)
    );

    led_rgb_controller secondary_led_inst (
        .led_color(secondary_led_color),
        .led_r(secondary_led_r),
        .led_g(secondary_led_g),
        .led_b(secondary_led_b)
    );

endmodule
