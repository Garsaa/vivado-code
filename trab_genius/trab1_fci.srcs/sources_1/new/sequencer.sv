module sequencer(
    input logic [3:0] seq_index,
    output logic [1:0] current_dir
);
    always_comb begin
        case (seq_index)
            4'd0: current_dir = 2'd1; // RIGHT
            4'd1: current_dir = 2'd0; // UP
            4'd2: current_dir = 2'd3; // LEFT
            4'd3: current_dir = 2'd2; // DOWN
            4'd4: current_dir = 2'd0; // UP
            // 4'd5: current_dir = 2'd3; // LEFT
            // 4'd6: current_dir = 2'd1; // RIGHT
            // 4'd7: current_dir = 2'd2; // DOWN
            // 4'd8: current_dir = 2'd1; // RIGHT
            // 4'd9: current_dir = 2'd2; // DOWN
            default: current_dir = 2'd0;
        endcase
    end

endmodule
