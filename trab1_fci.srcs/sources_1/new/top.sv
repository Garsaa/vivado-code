module top(
    input logic clk,

    output logic led_r,
    output logic led_g,
    output logic led_b
);

    logic clk1hz;
    logic [1:0] led_color;


    clkdiv #( .DIV(100000000) ) div1hz (
        .clk(clk),
        .tick(div1hz)
    );

    fsm_game fsm_inst (
        .clk(clk1hz),
        .led_color(led_color)
    );

    led_rgb_controller led_inst (
        .led_color(led_color),
        .led_r(led_r),
        .led_g(led_g),
        .led_b(led_b)
    );

endmodule
