//==============================================================================
// systolic_top.v
// Top-level output-stationary systolic matrix-multiply accelerator.
//
// Hierarchy:
//   input_buffers -> controller -> systolic_array -> output_regs
//==============================================================================

`timescale 1ns / 1ps

module systolic_top #(
    parameter integer N      = 4,
    parameter integer DATA_W = 8,
    parameter integer ACC_W  = 32
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     start,

    // Matrix load port
    input  wire                     wr_en,
    input  wire                     wr_sel_b,
    input  wire [$clog2(N*N)-1:0]   wr_addr,
    input  wire signed [DATA_W-1:0] wr_data,

    output wire                     done,
    output wire [15:0]              cycle_count,
    output wire signed [ACC_W-1:0]  c_out [0:N-1][0:N-1]
);

    wire signed [DATA_W-1:0] a_mem [0:N*N-1];
    wire signed [DATA_W-1:0] b_mem [0:N*N-1];

    wire                     clear;
    wire                     enable;
    wire signed [DATA_W-1:0] a_west  [0:N-1];
    wire signed [DATA_W-1:0] b_north [0:N-1];
    wire signed [ACC_W-1:0]  c_pe    [0:N-1][0:N-1];

    input_buffers #(
        .N      (N),
        .DATA_W (DATA_W)
    ) u_buf (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_en    (wr_en),
        .wr_sel_b (wr_sel_b),
        .wr_addr  (wr_addr),
        .wr_data  (wr_data),
        .a_mem    (a_mem),
        .b_mem    (b_mem)
    );

    controller #(
        .N      (N),
        .DATA_W (DATA_W)
    ) u_ctrl (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),
        .a_mem       (a_mem),
        .b_mem       (b_mem),
        .clear       (clear),
        .enable      (enable),
        .a_west      (a_west),
        .b_north     (b_north),
        .done        (done),
        .cycle_count (cycle_count)
    );

    systolic_array #(
        .N      (N),
        .DATA_W (DATA_W),
        .ACC_W  (ACC_W)
    ) u_array (
        .clk     (clk),
        .rst_n   (rst_n),
        .clear   (clear),
        .enable  (enable),
        .a_west  (a_west),
        .b_north (b_north),
        .c_pe    (c_pe)
    );

    output_regs #(
        .N     (N),
        .ACC_W (ACC_W)
    ) u_out (
        .clk     (clk),
        .rst_n   (rst_n),
        .capture (done),
        .c_pe    (c_pe),
        .c_out   (c_out)
    );

endmodule
