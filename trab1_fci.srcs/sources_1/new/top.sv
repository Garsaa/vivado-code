module top(
    input logic clk,
    input logic btnc,

    output logic led_r,
    output logic led_g,
    output logic led_b,
    output logic walker_led_b,
    output logic walker_led_g,
    output logic walker_led_r,

    output logic [6:0] seg,
    output logic [7:0] an
);
    logic clk1hz;
    logic [1:0] led_color;
    logic [1:0] walker_led_color;
    logic [3:0] fsm_count_3;

    clkdiv #( .DIV(100000000) ) div1hz (
        .clk(clk),
        .tick(clk1hz)
    );

    fsm_game fsm_inst (
        .clk(clk1hz),
        .btnc(btnc),
        .led_color(led_color),
        .walker_led_color(walker_led_color),
        .fsm_count_3(fsm_count_3)
    );

    led_rgb_controller led_inst (
        .led_color(led_color),
        .led_r(led_r),
        .led_g(led_g),
        .led_b(led_b)
    );

    led_rgb_controller second_led_inst (
        .led_color(walker_led_color),
        .led_r(walker_led_r),
        .led_g(walker_led_g),
        .led_b(walker_led_b)
    );

     display_controller display_inst (
        .BCD(fsm_count_3),
        .seg(seg),
        .an(an)
    );

endmodule
