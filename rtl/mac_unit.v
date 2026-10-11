//==============================================================================
// mac_unit.v
// Combinational Multiply-Accumulate: y = acc + (a * b)
// Signed integer / fixed-point operands (DATA_W), wider accumulator (ACC_W).
//==============================================================================

`timescale 1ns / 1ps

module mac_unit #(
    parameter integer DATA_W = 8,
    parameter integer ACC_W  = 32
) (
    input  wire signed [DATA_W-1:0] a,
    input  wire signed [DATA_W-1:0] b,
    input  wire signed [ACC_W-1:0]  acc,
    output wire signed [ACC_W-1:0]  y
);

    // Full-precision signed product, then sign-extend into accumulator width.
    wire signed [2*DATA_W-1:0] product;

    assign product = a * b;
    assign y       = acc + {{(ACC_W - 2*DATA_W){product[2*DATA_W-1]}}, product};

endmodule
