//==============================================================================
// controller.v
// Systolic-array FSM and skewed feed schedule (output-stationary).
//
// FSM: IDLE -> CLEAR -> RUN -> DONE -> IDLE
//
// Injection skew (boundary time t):
//   A[i][k] on west[i]  when t == i + k
//   B[k][j] on north[j] when t == j + k
//
// PE(i,j) sees pair (A[i][k], B[k][j]) at RUN index r = i + j + k.
// Last MAC at r = 3N-3. RUN = 3N-2 cycles. start -> done = 3N cycles.
//==============================================================================

`timescale 1ns / 1ps

module controller #(
    parameter integer N      = 4,
    parameter integer DATA_W = 8
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     start,

    input  wire signed [DATA_W-1:0] a_mem [0:N*N-1],
    input  wire signed [DATA_W-1:0] b_mem [0:N*N-1],

    output reg                      clear,
    output reg                      enable,
    output reg  signed [DATA_W-1:0] a_west  [0:N-1],
    output reg  signed [DATA_W-1:0] b_north [0:N-1],
    output reg                      done,
    output reg  [15:0]              cycle_count
);

    localparam integer R_LAST     = (3 * N) - 3;
    localparam integer T_INJ_LAST = (2 * N) - 2;

    localparam [1:0] S_IDLE  = 2'd0;
    localparam [1:0] S_CLEAR = 2'd1;
    localparam [1:0] S_RUN   = 2'd2;
    localparam [1:0] S_DONE  = 2'd3;

    reg [1:0]  state;
    reg [15:0] r;

    integer i;
    integer j;
    integer k;
    integer idx;

    // next_t: injection index to load onto the boundary this clock edge
    reg [15:0] next_t;
    reg        load_feeds;
    reg        zero_feeds;

    reg signed [DATA_W-1:0] a_next [0:N-1];
    reg signed [DATA_W-1:0] b_next [0:N-1];

    always @(*) begin
        // Defaults
        next_t     = 16'd0;
        load_feeds = 1'b0;
        zero_feeds = 1'b0;

        case (state)
            S_CLEAR: begin
                next_t     = 16'd0;
                load_feeds = 1'b1;
            end
            S_RUN: begin
                if (r >= R_LAST[15:0]) begin
                    zero_feeds = 1'b1;
                end
                else begin
                    next_t     = r + 16'd1;
                    load_feeds = 1'b1;
                end
            end
            default: begin
                zero_feeds = 1'b1;
            end
        endcase

        // Decode skewed A/B for next_t
        for (i = 0; i < N; i = i + 1) begin
            a_next[i] = {DATA_W{1'b0}};
            if (load_feeds && next_t <= T_INJ_LAST[15:0] && next_t >= i[15:0]) begin
                k = next_t - i;
                if (k < N) begin
                    idx       = i * N + k;
                    a_next[i] = a_mem[idx];
                end
            end
        end

        for (j = 0; j < N; j = j + 1) begin
            b_next[j] = {DATA_W{1'b0}};
            if (load_feeds && next_t <= T_INJ_LAST[15:0] && next_t >= j[15:0]) begin
                k = next_t - j;
                if (k < N) begin
                    idx       = k * N + j;
                    b_next[j] = b_mem[idx];
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            r           <= 16'd0;
            clear       <= 1'b0;
            enable      <= 1'b0;
            done        <= 1'b0;
            cycle_count <= 16'd0;
            for (i = 0; i < N; i = i + 1) begin
                a_west[i]  <= {DATA_W{1'b0}};
                b_north[i] <= {DATA_W{1'b0}};
            end
        end
        else begin
            case (state)
                S_IDLE: begin
                    done   <= 1'b0;
                    clear  <= 1'b0;
                    enable <= 1'b0;
                    r      <= 16'd0;
                    for (i = 0; i < N; i = i + 1) begin
                        a_west[i]  <= {DATA_W{1'b0}};
                        b_north[i] <= {DATA_W{1'b0}};
                    end

                    if (start) begin
                        state       <= S_CLEAR;
                        clear       <= 1'b1;
                        cycle_count <= 16'd1;
                    end
                end

                S_CLEAR: begin
                    clear       <= 1'b0;
                    enable      <= 1'b1;
                    r           <= 16'd0;
                    state       <= S_RUN;
                    cycle_count <= cycle_count + 16'd1;

                    for (i = 0; i < N; i = i + 1) begin
                        a_west[i]  <= a_next[i];
                        b_north[i] <= b_next[i];
                    end
                end

                S_RUN: begin
                    clear       <= 1'b0;
                    enable      <= 1'b1;
                    cycle_count <= cycle_count + 16'd1;

                    if (r >= R_LAST[15:0]) begin
                        enable <= 1'b0;
                        done   <= 1'b1;
                        state  <= S_DONE;
                        for (i = 0; i < N; i = i + 1) begin
                            a_west[i]  <= {DATA_W{1'b0}};
                            b_north[i] <= {DATA_W{1'b0}};
                        end
                    end
                    else begin
                        r <= r + 16'd1;
                        for (i = 0; i < N; i = i + 1) begin
                            a_west[i]  <= a_next[i];
                            b_north[i] <= b_next[i];
                        end
                    end
                end

                S_DONE: begin
                    done   <= 1'b1;
                    clear  <= 1'b0;
                    enable <= 1'b0;
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
