`timescale 1ns/1ps

module tb_top;

  // =======================
  // Clock 100 MHz (10 ns)
  // =======================
  logic clk = 0;
  always #5 clk = ~clk;

  // =======================
  // DUT I/Os
  // =======================
  logic led_r, led_g, led_b;

  // =======================
  // DUT
  // =======================
  top dut (
    .clk   (clk),
    .led_r (led_r),
    .led_g (led_g),
    .led_b (led_b)
  );

  // Deixa o divisor bem pequeno pra simular rápido
  // (ajuste se quiser). Caminho: tb_top.dut.div1hz.DIV
  defparam tb_top.dut.div1hz.DIV = 8;

  // =======================
  // Waveform (VCD)
  // =======================
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_top);
  end

  // =======================
  // Util: mapeia (r,g,b) -> cor
  // =======================
  typedef enum int {WHITE=0, RED=1, GREEN=2, YELLOW=3, UNKNOWN=-1} color_t;

  function color_t cur_color();
    if ( led_r &&  led_g &&  led_b)   return WHITE;   // default do controlador
    if ( led_r &&  led_g && !led_b)   return YELLOW;
    if ( led_r && !led_g && !led_b)   return RED;
    if (!led_r &&  led_g && !led_b)   return GREEN;
    return UNKNOWN;
  endfunction

  function string color_name(color_t c);
    case (c)
      WHITE:  return "WHITE";
      RED:    return "RED";
      GREEN:  return "GREEN";
      YELLOW: return "YELLOW";
      default:return "UNKNOWN";
    endcase
  endfunction

  // =======================
  // Checagem da sequência
  // =======================
  int tick_count = 0;
  color_t expected, got;

  // A FSM avança em @posedge clk1hz (pulso do divisor),
  // então sincronizamos por ele.
  initial begin
    // Espera o DUT estabilizar um pouco
    repeat (5) @(posedge clk);

    // Valida alguns passos
    repeat (12) begin
      @(posedge dut.clk1hz);  // acesso hierárquico ao "tick" lento
      tick_count++;

      // 1º tick: FSM sai de START e coloca led_color = 2'b00 -> WHITE
      if (tick_count == 1) expected = WHITE;
      else begin
        // Depois: RED -> GREEN -> YELLOW -> repete
        case ((tick_count-2) % 3)
          0: expected = RED;
          1: expected = GREEN;
          2: expected = YELLOW;
        endcase
      end

      got = cur_color();
      $display("[%0t] tick=%0d  expected=%s  got=%s  (r=%0b g=%0b b=%0b)",
               $time, tick_count, color_name(expected), color_name(got),
               led_r, led_g, led_b);

      assert (got == expected)
        else $fatal(1, "Color mismatch at tick %0d: expected %s got %s",
                    tick_count, color_name(expected), color_name(got));
    end

    $display("✅ Test PASSED");
    $finish;
  end

endmodule
