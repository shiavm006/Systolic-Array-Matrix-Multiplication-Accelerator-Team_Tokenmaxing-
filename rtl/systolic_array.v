//==============================================================================
// systolic_array.v
// N x N grid of output-stationary PEs.
//
//   a_west[i]  --> row i, left edge;  a propagates PE[i][j] -> PE[i][j+1]
//   b_north[j] --> col j, top edge;   b propagates PE[i][j] -> PE[i+1][j]
//   c_pe[i][j] holds C[i][j]
//==============================================================================

`timescale 1ns / 1ps

module systolic_array #(
    parameter integer N      = 4,
    parameter integer DATA_W = 8,
    parameter integer ACC_W  = 32
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     clear,
    input  wire                     enable,

    input  wire signed [DATA_W-1:0] a_west  [0:N-1],
    input  wire signed [DATA_W-1:0] b_north [0:N-1],

    output wire signed [ACC_W-1:0]  c_pe    [0:N-1][0:N-1]
);

    // Horizontal a links: a_h[i][j] is a_in to PE(i,j)
    // Vertical   b links: b_v[i][j] is b_in to PE(i,j)
    wire signed [DATA_W-1:0] a_h [0:N-1][0:N];
    wire signed [DATA_W-1:0] b_v [0:N][0:N-1];

    genvar gi, gj;

    // West / north boundary injection
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : g_west
            assign a_h[gi][0] = a_west[gi];
        end
        for (gj = 0; gj < N; gj = gj + 1) begin : g_north
            assign b_v[0][gj] = b_north[gj];
        end
    endgenerate

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : g_row
            for (gj = 0; gj < N; gj = gj + 1) begin : g_col

                wire signed [DATA_W-1:0] a_out_w;
                wire signed [DATA_W-1:0] b_out_w;

                pe #(
                    .DATA_W (DATA_W),
                    .ACC_W  (ACC_W)
                ) u_pe (
                    .clk    (clk),
                    .rst_n  (rst_n),
                    .clear  (clear),
                    .enable (enable),
                    .a_in   (a_h[gi][gj]),
                    .b_in   (b_v[gi][gj]),
                    .a_out  (a_out_w),
                    .b_out  (b_out_w),
                    .c_out  (c_pe[gi][gj])
                );

                assign a_h[gi][gj+1] = a_out_w;
                assign b_v[gi+1][gj] = b_out_w;

            end
        end
    endgenerate

endmodule
