//==============================================================================
// pe.v
// Output-stationary Processing Element.
//
//   - Holds one C_ij in an accumulator register
//   - On each enabled cycle: C <= C + a_in * b_in  (MAC)
//   - Passes a east (a_out) and b south (b_out) with one-cycle register delay
//
// Systolic data movement (array view):
//   A elements travel left -> right
//   B elements travel top  -> bottom
//   C stays in the PE until CLEAR / read-out
//==============================================================================

`timescale 1ns / 1ps

module pe #(
    parameter integer DATA_W = 8,
    parameter integer ACC_W  = 32
) (
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     clear,      // zero the accumulator
    input  wire                     enable,     // perform MAC this cycle

    input  wire signed [DATA_W-1:0] a_in,
    input  wire signed [DATA_W-1:0] b_in,

    output reg  signed [DATA_W-1:0] a_out,
    output reg  signed [DATA_W-1:0] b_out,
    output reg  signed [ACC_W-1:0]  c_out
);

    wire signed [ACC_W-1:0] mac_y;

    mac_unit #(
        .DATA_W (DATA_W),
        .ACC_W  (ACC_W)
    ) u_mac (
        .a   (a_in),
        .b   (b_in),
        .acc (c_out),
        .y   (mac_y)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out <= {DATA_W{1'b0}};
            b_out <= {DATA_W{1'b0}};
            c_out <= {ACC_W{1'b0}};
        end
        else begin
            // Systolic pipeline registers (always shift when not in reset)
            a_out <= a_in;
            b_out <= b_in;

            if (clear) begin
                c_out <= {ACC_W{1'b0}};
            end
            else if (enable) begin
                c_out <= mac_y;
            end
        end
    end

endmodule
