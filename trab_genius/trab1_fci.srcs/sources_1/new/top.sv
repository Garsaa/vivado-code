module top(
    // Clock
    input logic clk,

    // Buttons
    input logic btnu, 
    input logic btnl, 
    input logic btnr,
    input logic btnd, 
    input logic btnc,

    // 7 Segment Display
    output logic [6:0] seg,
    output logic [7:0] an,

    // LED 16 RGB colors
    output logic led_r,
    output logic led_g,
    output logic led_b,

    // 16 LEDs
    output logic [15:0] led
);

    logic clk_100hz;
    logic clk_1khz;
    logic [1:0] led_color;
    logic [1:0] current_dir;
    logic show_char;
    logic error;
    logic win;
    logic reset_game;
    logic [3:0] seq_index_fsm;
    logic leds_on;

    always_comb begin
        if(leds_on) begin
            led <= 16'hFFFF;
        end else begin
            led <= 16'h0000;
        end
    end

    clkdiv #( .DIV(1000000) ) div100hz (
        .clk(clk),
        .tick(clk_100hz)
    );

    clkdiv #(.DIV(100000) ) div1khz (
        .clk(clk),
        .tick(clk_1khz)
    );

    fsm_game fsm_inst (
        .clk(clk_100hz),
        .btnu(btnu),
        .btnl(btnl),
        .btnr(btnr),
        .btnd(btnd),
        .leds_on(leds_on),
        .btnc(btnc),
        .seq_index(seq_index_fsm),
        .current_dir(current_dir),
        .show_char(show_char),
        .error(error),
        .win(win),
        .led_color(led_color),
        .reset_game(reset_game)
    );

    sequencer seq_inst (
        .seq_index(seq_index_fsm),
        .current_dir(current_dir)
    );

    display_controller disp_inst (
        .show_char(show_char),
        .clk(clk_1khz),
        .current_dir(current_dir),
        .win(win),
        .error(error),
        .seg(seg),
        .an(an)
    );

    led_rgb_controller led_inst (
        .led_color(led_color),
        .led_r(led_r),
        .led_g(led_g),
        .led_b(led_b)
    );

endmodule
