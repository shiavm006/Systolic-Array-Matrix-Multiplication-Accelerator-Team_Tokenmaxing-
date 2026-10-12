//==============================================================================
// tb_pe.v
// Directed PE / MAC tests:
//   3*4, -2*5, 127*127, -128*-128, accumulate chain, clear, hold.
//==============================================================================

`timescale 1ns / 1ps

module tb_pe;

    localparam integer DATA_W = 8;
    localparam integer ACC_W  = 32;

    reg                      clk;
    reg                      rst_n;
    reg                      clear;
    reg                      enable;
    reg  signed [DATA_W-1:0] a_in;
    reg  signed [DATA_W-1:0] b_in;

    wire signed [DATA_W-1:0] a_out;
    wire signed [DATA_W-1:0] b_out;
    wire signed [ACC_W-1:0]  c_out;

    integer errors;

    pe #(
        .DATA_W (DATA_W),
        .ACC_W  (ACC_W)
    ) dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .clear  (clear),
        .enable (enable),
        .a_in   (a_in),
        .b_in   (b_in),
        .a_out  (a_out),
        .b_out  (b_out),
        .c_out  (c_out)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // All stimulus changes on negedge; DUT samples on posedge.
    task automatic tick;
        begin
            @(negedge clk);
        end
    endtask

    task automatic check_c;
        input signed [ACC_W-1:0] exp_c;
        input [255:0]            name;
        begin
            @(posedge clk);
            #1;
            if (c_out !== exp_c) begin
                $display("FAIL %-24s  got=%0d  exp=%0d", name, c_out, exp_c);
                errors = errors + 1;
            end
            else begin
                $display("PASS %-24s  c=%0d", name, c_out);
            end
        end
    endtask

    initial begin
        errors = 0;
        rst_n  = 1'b0;
        clear  = 1'b0;
        enable = 1'b0;
        a_in   = 0;
        b_in   = 0;

        $dumpfile("sim/tb_pe.vcd");
        $dumpvars(0, tb_pe);

        // Reset
        repeat (3) tick;
        rst_n = 1'b1;
        tick;

        //--------------------------------------------------------------------
        // Case 1: 3 x 4 = 12
        //--------------------------------------------------------------------
        tick;
        clear  = 1'b1;
        enable = 1'b0;
        check_c(32'sd0, "clear before 3x4");

        tick;
        clear  = 1'b0;
        a_in   = 8'sd3;
        b_in   = 8'sd4;
        enable = 1'b1;
        check_c(32'sd12, "3 x 4");

        //--------------------------------------------------------------------
        // Case 2: -2 x 5 = -10
        //--------------------------------------------------------------------
        tick;
        enable = 1'b0;
        clear  = 1'b1;
        a_in   = 0;
        b_in   = 0;
        check_c(32'sd0, "clear before -2x5");

        tick;
        clear  = 1'b0;
        a_in   = -8'sd2;
        b_in   = 8'sd5;
        enable = 1'b1;
        check_c(-32'sd10, "-2 x 5");

        //--------------------------------------------------------------------
        // Case 3: 127 x 127 = 16129
        //--------------------------------------------------------------------
        tick;
        enable = 1'b0;
        clear  = 1'b1;
        check_c(32'sd0, "clear before 127x127");

        tick;
        clear  = 1'b0;
        a_in   = 8'sd127;
        b_in   = 8'sd127;
        enable = 1'b1;
        check_c(32'sd16129, "127 x 127");

        //--------------------------------------------------------------------
        // Case 4: -128 x -128 = 16384
        //--------------------------------------------------------------------
        tick;
        enable = 1'b0;
        clear  = 1'b1;
        check_c(32'sd0, "clear before -128x-128");

        tick;
        clear  = 1'b0;
        a_in   = -8'sd128;
        b_in   = -8'sd128;
        enable = 1'b1;
        check_c(32'sd16384, "-128 x -128");

        //--------------------------------------------------------------------
        // Accumulate: 3*4 + 5*6 = 42
        //--------------------------------------------------------------------
        tick;
        enable = 1'b0;
        clear  = 1'b1;
        check_c(32'sd0, "clear before acc");

        tick;
        clear  = 1'b0;
        a_in   = 8'sd3;
        b_in   = 8'sd4;
        enable = 1'b1;
        check_c(32'sd12, "acc step1 3x4");

        tick;
        a_in   = 8'sd5;
        b_in   = 8'sd6;
        enable = 1'b1;
        check_c(32'sd42, "acc step2 +5x6");

        //--------------------------------------------------------------------
        // Hold when enable=0
        //--------------------------------------------------------------------
        tick;
        enable = 1'b0;
        a_in   = 8'sd9;
        b_in   = 8'sd9;
        check_c(32'sd42, "hold when enable=0");

        // Pass-through check (a_out/b_out lag one cycle from last enabled drive)
        tick;
        a_in   = 8'sd11;
        b_in   = 8'sd22;
        enable = 1'b0;
        @(posedge clk);
        #1;
        if (a_out !== 8'sd11 || b_out !== 8'sd22) begin
            $display("FAIL pass-through a=%0d b=%0d", a_out, b_out);
            errors = errors + 1;
        end
        else begin
            $display("PASS pass-through            a=%0d b=%0d", a_out, b_out);
        end

        if (errors == 0)
            $display("\n*** tb_pe: ALL TESTS PASSED ***\n");
        else
            $display("\n*** tb_pe: %0d FAILURE(S) ***\n", errors);

        $finish;
    end

endmodule
