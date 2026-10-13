//==============================================================================
// input_buffers.v
// Simple dual matrix scratchpad for A and B (row-major).
// Host / testbench writes elements before asserting start.
//==============================================================================

`timescale 1ns / 1ps

module input_buffers #(
    parameter integer N      = 4,
    parameter integer DATA_W = 8
) (
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     wr_en,
    input  wire                     wr_sel_b,   // 0 = write A, 1 = write B
    input  wire [$clog2(N*N)-1:0]   wr_addr,
    input  wire signed [DATA_W-1:0] wr_data,

    output wire signed [DATA_W-1:0] a_mem [0:N*N-1],
    output wire signed [DATA_W-1:0] b_mem [0:N*N-1]
);

    reg signed [DATA_W-1:0] a_reg [0:N*N-1];
    reg signed [DATA_W-1:0] b_reg [0:N*N-1];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < N*N; i = i + 1) begin
                a_reg[i] <= {DATA_W{1'b0}};
                b_reg[i] <= {DATA_W{1'b0}};
            end
        end
        else if (wr_en) begin
            if (wr_sel_b)
                b_reg[wr_addr] <= wr_data;
            else
                a_reg[wr_addr] <= wr_data;
        end
    end

    generate
        genvar gi;
        for (gi = 0; gi < N*N; gi = gi + 1) begin : g_out
            assign a_mem[gi] = a_reg[gi];
            assign b_mem[gi] = b_reg[gi];
        end
    endgenerate

endmodule
