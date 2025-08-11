module fsm_game(
    input logic clk,
    input logic btnu, btnl, btnr, btnd, btnc,
    input logic [1:0] current_dir,
    output logic win,
    output logic leds_on,
    output logic show_char,
    output logic error,
    output logic [1:0] led_color,
    output logic reset_game,
    output logic [3:0] seq_index
);

    typedef enum logic [2:0] { START, RESET, SHOW, SHOW_LOOP, WAIT_AND_CHECK_INPUT, SUCCESS, FINAL, FAIL } state_t;
    state_t state = START;

    logic [3:0] input_index;
    logic [3:0] sequence_size;

    logic btnu_reg;
    logic btnd_reg;
    logic btnl_reg;
    logic btnr_reg;
    logic btnc_reg;

    logic [31:0] count = 0;
    logic [31:0] count_2 = 0;
    logic tick = 0;
    logic tick_2 = 0;

    always_ff @(posedge clk) begin
        if (!btnc && btnc_reg) begin 
            state <= RESET;
        end else 
            case (state)

                START: begin
                    led_color <= 2'b00;
                    if (!btnc && btnc_reg) begin 
                        state <= RESET;
                    end
                end

                RESET: begin
                    reset_game <= 1;
                    sequence_size <= 1;
                    error <= 0;
                    win<=0;
                    leds_on <= 0;
                    input_index <= 0;
                    state <= SHOW;
                end

                SHOW: begin
                    reset_game <= 0;
                    show_char <= 1;
                    input_index <= 0;
                    seq_index <= 0;
                    led_color <= 2'b01; // Amarelo
                    state <= SHOW_LOOP;
                end

                SHOW_LOOP: begin
                    if (count == 100 - 1) begin
                        count <= 0;       
                        tick <= 1;         
                    end else begin
                        count <= count + 1;   
                        tick <= 0;            
                    end

                    if(seq_index < sequence_size - 1) begin
                        if(tick) begin
                            seq_index <= seq_index + 1;
                        end    
                    end else begin
                    if (count_2 == 100 - 1) begin       
                        seq_index <= 0;
                        show_char <= 0;
                        led_color <= 2'b10;
                        count_2 <= 0;
                        state <= WAIT_AND_CHECK_INPUT;       
                    end else begin
                        count_2 <= count_2 + 1;
                        end
                    end
                end

                WAIT_AND_CHECK_INPUT: begin
                    leds_on <= 0;

                    if((!btnu && btnu_reg)
                        || (!btnd && btnd_reg)
                        || (!btnl && btnl_reg)
                        || (!btnr && btnr_reg)
                    ) begin
                        if((!btnu && btnu_reg && current_dir == 2'd0)
                            || (!btnd && btnd_reg && current_dir == 2'd2)
                            || (!btnl && btnl_reg && current_dir == 2'd3)
                            || (!btnr && btnr_reg && current_dir == 2'd1)
                        ) begin
                            seq_index <= seq_index + 1;
                            leds_on <= 1;
                            if (input_index + 1 == sequence_size) begin
                                sequence_size <= sequence_size + 1;
                                state <= SUCCESS;
                            end else begin
                                input_index <= input_index + 1;
                                state <= WAIT_AND_CHECK_INPUT;
                            end
                        end else begin
                            state <= FAIL;
                        end
                    end
                end

                SUCCESS: begin
                    if (sequence_size == 6)begin
                        state <= FINAL;    
                    end else begin
                        leds_on <= 0;
                        state <= SHOW;
                    end
                end

                FINAL: begin
                    win <= 1;
                    leds_on <= 1;
                end

                FAIL: begin
                    led_color <= 2'b11; // Vermelho
                    error <= 1;
                end

                default: state <= RESET;
            endcase
        btnu_reg <= btnu;
        btnd_reg <= btnd;
        btnl_reg <= btnl;
        btnr_reg <= btnr;
        btnc_reg <= btnc;
    end


endmodule
