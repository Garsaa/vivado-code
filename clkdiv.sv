module clkdiv #(
    parameter integer DIV = 50000
)(
    input  logic clk,                           
    output logic tick              
);

    logic [31:0] count = 0;

    always_ff @(posedge clk) begin
        if (count == DIV - 1) begin
            count <= 0;
            tick <= 1; 
        end else begin
            count <= count + 1;
            tick <= 0;
        end
    end

endmodule
