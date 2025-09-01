`timescale 1ns / 1ps

module leds_controller(
    input  logic [15:0] switchs,
    output logic [15:0] led
);
    assign led = switchs;
endmodule