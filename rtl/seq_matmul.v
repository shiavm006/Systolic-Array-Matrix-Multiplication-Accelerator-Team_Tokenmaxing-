//==============================================================================
// seq_matmul.v
// Baseline: one MAC per cycle, row-major C[i][j] += A[i][k]*B[k][j].
// Latency: N^3 MAC cycles + 1 clear = N^3 + 1 (65 for N=4).
//==============================================================================

`timescale 1ns / 1ps

module seq_matmul #(
    parameter integer N      = 4,
    parameter integer DATA_W = 8,
    parameter integer ACC_W  = 32
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     start,

    input  wire signed [DATA_W-1:0] a_mem [0:N*N-1],
    input  wire signed [DATA_W-1:0] b_mem [0:N*N-1],

    output reg                      done,
    output reg  [15:0]              cycle_count,
    output reg  signed [ACC_W-1:0]  c_out [0:N-1][0:N-1]
);

    localparam [1:0] S_IDLE  = 2'd0;
    localparam [1:0] S_CLEAR = 2'd1;
    localparam [1:0] S_RUN   = 2'd2;
    localparam [1:0] S_DONE  = 2'd3;

    reg [1:0] state;
    reg [$clog2(N):0] i, j, k;

    wire signed [DATA_W-1:0] a_el = a_mem[i*N + k];
    wire signed [DATA_W-1:0] b_el = b_mem[k*N + j];
    wire signed [2*DATA_W-1:0] prod = a_el * b_el;

    integer ii, jj;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            done        <= 1'b0;
            cycle_count <= 16'd0;
            i <= 0; j <= 0; k <= 0;
            for (ii = 0; ii < N; ii = ii + 1)
                for (jj = 0; jj < N; jj = jj + 1)
                    c_out[ii][jj] <= {ACC_W{1'b0}};
        end
        else begin
            case (state)
                S_IDLE: begin
                    done <= 1'b0;
                    i <= 0; j <= 0; k <= 0;
                    if (start) begin
                        state       <= S_CLEAR;
                        cycle_count <= 16'd0;
                    end
                end

                S_CLEAR: begin
                    // One clear cycle, then N^3 MAC cycles -> total N^3+1
                    for (ii = 0; ii < N; ii = ii + 1)
                        for (jj = 0; jj < N; jj = jj + 1)
                            c_out[ii][jj] <= {ACC_W{1'b0}};
                    i <= 0; j <= 0; k <= 0;
                    state       <= S_RUN;
                    cycle_count <= 16'd1;
                end

                S_RUN: begin
                    c_out[i][j] <= c_out[i][j] +
                                   {{(ACC_W-2*DATA_W){prod[2*DATA_W-1]}}, prod};
                    cycle_count <= cycle_count + 16'd1;

                    // Advance k, then j, then i
                    if (k == N-1) begin
                        k <= 0;
                        if (j == N-1) begin
                            j <= 0;
                            if (i == N-1) begin
                                state <= S_DONE;
                                done  <= 1'b1;
                            end
                            else begin
                                i <= i + 1;
                            end
                        end
                        else begin
                            j <= j + 1;
                        end
                    end
                    else begin
                        k <= k + 1;
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                    if (!start) begin
                        state <= S_IDLE;
                        done  <= 1'b0;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
