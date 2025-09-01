module seg_7_enum (
    input  logic [3:0] value,  // valor BCD (0 a 9)
    output logic [6:0] seg     // segmentos {a,b,c,d,e,f,g}
);
    logic [6:0] raw;

    always_comb begin
        case(value)
            4'd0: raw = 7'b1000000;
            4'd1: raw = 7'b1111001;
            4'd2: raw = 7'b0100100;
            4'd3: raw = 7'b0110000;
            4'd4: raw = 7'b0011001;
            4'd5: raw = 7'b0010010;
            4'd6: raw = 7'b0000010;
            4'd7: raw = 7'b1111000;
            4'd8: raw = 7'b0000000;
            4'd9: raw = 7'b0010000;
            default: raw = 7'b1111111; // nada acende
        endcase
    end

    // Inversão para ânodo comum
    assign seg = raw;
endmodule
