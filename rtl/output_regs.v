//==============================================================================
// output_regs.v
// Captures C from the PE array when done pulses / stays high.
//==============================================================================

`timescale 1ns / 1ps

module output_regs #(
    parameter integer N     = 4,
    parameter integer ACC_W = 32
) (
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire                    capture,     // usually 'done'
    input  wire signed [ACC_W-1:0] c_pe  [0:N-1][0:N-1],
    output reg  signed [ACC_W-1:0] c_out [0:N-1][0:N-1]
);

    integer i, j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < N; i = i + 1)
                for (j = 0; j < N; j = j + 1)
                    c_out[i][j] <= {ACC_W{1'b0}};
        end
        else if (capture) begin
            for (i = 0; i < N; i = i + 1)
                for (j = 0; j < N; j = j + 1)
                    c_out[i][j] <= c_pe[i][j];
        end
    end

endmodule
