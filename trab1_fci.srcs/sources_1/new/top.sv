module top (
  input  logic clk,
  input  logic btnc,
  output logic pwm_out
);

  localparam int unsigned CLK_FREQ   = 100_000_000;
  localparam int unsigned AUDIO_HZ   = 1_000;
  localparam int unsigned PHASE_BITS = 32;
  localparam int unsigned PWM_BITS   = 8;

  localparam longint unsigned PHASE_INC =
      ( (64'd1 << PHASE_BITS) * AUDIO_HZ ) / CLK_FREQ;

  logic btn_meta, btn_sync, btn_stable, btn_stable_d;
  logic [20:0] db_cnt;

  always_ff @(posedge clk) begin
    btn_meta <= btnc;
    btn_sync <= btn_meta;
  end

  always_ff @(posedge clk) begin
    if (btn_sync != btn_stable) begin
      db_cnt     <= 0;
    end else if (db_cnt != 21'd2_000_000) begin
      db_cnt     <= db_cnt + 1;
    end
    if (db_cnt == 21'd2_000_000) begin
      btn_stable <= btn_sync;
    end
  end

  always_ff @(posedge clk) btn_stable_d <= btn_stable;
  wire btn_rise = btn_stable & ~btn_stable_d;

  logic [1:0] wave_sel = 2'd0;
  always_ff @(posedge clk) if (btn_rise) wave_sel <= wave_sel + 2'd1;

  logic [PHASE_BITS-1:0] phase;
  always_ff @(posedge clk) phase <= phase + PHASE_INC;

  wire        msb = phase[PHASE_BITS-1];
  wire [7:0]  idx8  = phase[PHASE_BITS-1 -: 8];
  wire [7:0]  ramp8 = phase[PHASE_BITS-2 -: 8];
  wire [7:0]  tri8  = msb ? ~ramp8 : ramp8;
  wire [7:0]  sqr8  = msb ? 8'hFF : 8'h00;

  function automatic [7:0] sine_approx(input [7:0] t);
    logic signed [15:0] x, x2, x3;
    logic signed [31:0] yq;
    begin
      x  = ( {1'b0,t} - 9'sd128 ) <<< 7;
      x2 = (x * x) >>> 15;
      x3 = (x2 * x) >>> 15;
      yq = (3*x - x3);
      sine_approx = (yq >>> 9) + 8'd128;
    end
  endfunction

  wire [7:0] sin8 = sine_approx(tri8);

  logic [7:0] sample8;
  always_comb begin
    unique case (wave_sel)
      2'd0: sample8 = sin8;
      2'd1: sample8 = sqr8;
      default: sample8 = tri8;
    endcase
  end

  logic [PWM_BITS-1:0] pwm_cnt;
  always_ff @(posedge clk) pwm_cnt <= pwm_cnt + 1;
  assign pwm_out = (pwm_cnt < sample8);

endmodule
