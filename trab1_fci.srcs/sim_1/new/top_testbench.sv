`timescale 1ns/1ps

module tb_top;

  // Entradas do DUT
  logic clk  = 0;
  logic btnc = 0;

  // Saídas do DUT
  logic led_r, led_g, led_b;
  logic walker_led_b, walker_led_g, walker_led_r;

  // DUT
  top dut (
    .clk(clk),
    .btnc(btnc),
    .led_r(led_r),
    .led_g(led_g),
    .led_b(led_b),
    .walker_led_b(walker_led_b),
    .walker_led_g(walker_led_g),
    .walker_led_r(walker_led_r)
  );

  // Clock 100 MHz (10 ns)
  always #5 clk = ~clk;

  // Acelera o divisor para simulação (tick a cada 1000 ciclos)
  // Em hardware real use DIV=100_000_000
  defparam dut.div1hz.DIV = 1_000;

  // Estímulos mínimos
  initial begin
    // espera alguns ticks para estabilizar (FSM sai de START -> GREEN)
    repeat (5) @(posedge dut.clk1hz);

    // 1ª pressão do botão (segura por 3 ticks)
    btnc = 1; repeat (3) @(posedge dut.clk1hz); btnc = 0;

    // observa a sequência inteira
    repeat (30) @(posedge dut.clk1hz);

    // 2ª pressão
    btnc = 1; repeat (3) @(posedge dut.clk1hz); btnc = 0;

    // observa mais um ciclo
    repeat (60) @(posedge dut.clk1hz);

    $finish;
  end

  // Log simples: imprime bits a cada tick lento
  // (veh_rgb: R G B) (ped_rgb: R G B) (cores internas 2 bits)
  always @(posedge dut.clk1hz) begin
    $display("%0t  btnc=%0b  veh_rgb=%0b%0b%0b  ped_rgb=%0b%0b%0b  veh_col=%b  ped_col=%b",
      $time, btnc,
      led_r, led_g, led_b,
      walker_led_r, walker_led_g, walker_led_b,
      dut.led_color, dut.walker_led_color
    );
  end

endmodule
