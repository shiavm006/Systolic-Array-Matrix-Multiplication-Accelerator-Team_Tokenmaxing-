//==============================================================================
// tb_systolic.v
// System testbench for systolic_top vs software golden reference.
// Cases: identity, zero, corner extremes, and random matrices.
// Also reports cycle latency vs sequential baseline (N^3+1).
//==============================================================================

`timescale 1ns / 1ps

module tb_systolic;

    // Set N via plusarg: +N=3 or +N=4 (default 4)
    localparam integer DATA_W = 8;
    localparam integer ACC_W  = 32;

    integer N;
    integer SEQ_LAT;

    reg                      clk;
    reg                      rst_n;
    reg                      start;
    reg                      wr_en;
    reg                      wr_sel_b;
    reg  [7:0]               wr_addr;
    reg  signed [DATA_W-1:0] wr_data;

    // Max size 8 so one TB binary covers 3 and 4
    localparam integer NMAX = 8;

    wire                     done4;
    wire [15:0]              cycles4;
    wire signed [ACC_W-1:0]  c4 [0:3][0:3];

    wire                     done3;
    wire [15:0]              cycles3;
    wire signed [ACC_W-1:0]  c3 [0:2][0:2];

    integer errors;
    integer tests;
    integer seed;
    integer ti, tj, tk;
    integer exp_c;
    integer got_c;
    integer t;

    //--------------------------------------------------------------------
    // DUTs
    //--------------------------------------------------------------------
    systolic_top #(
        .N      (4),
        .DATA_W (DATA_W),
        .ACC_W  (ACC_W)
    ) dut4 (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),
        .wr_en       (wr_en),
        .wr_sel_b    (wr_sel_b),
        .wr_addr     (wr_addr[3:0]),
        .wr_data     (wr_data),
        .done        (done4),
        .cycle_count (cycles4),
        .c_out       (c4)
    );

    systolic_top #(
        .N      (3),
        .DATA_W (DATA_W),
        .ACC_W  (ACC_W)
    ) dut3 (
        .clk         (clk),
        .rst_n       (rst_n),
        .start       (start),
        .wr_en       (wr_en),
        .wr_sel_b    (wr_sel_b),
        .wr_addr     (wr_addr[3:0]),
        .wr_data     (wr_data),
        .done        (done3),
        .cycle_count (cycles3),
        .c_out       (c3)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Working matrices
    reg signed [DATA_W-1:0] A [0:NMAX*NMAX-1];
    reg signed [DATA_W-1:0] B [0:NMAX*NMAX-1];

    task automatic tick;
        begin
            @(negedge clk);
        end
    endtask

    task automatic apply_reset;
        begin
            rst_n     = 1'b0;
            start     = 1'b0;
            wr_en     = 1'b0;
            wr_sel_b  = 1'b0;
            wr_addr   = 0;
            wr_data   = 0;
            repeat (4) tick;
            rst_n = 1'b1;
            tick;
        end
    endtask

    task automatic load_matrices;
        integer idx;
        begin
            for (idx = 0; idx < N*N; idx = idx + 1) begin
                tick;
                wr_en    = 1'b1;
                wr_sel_b = 1'b0;
                wr_addr  = idx[7:0];
                wr_data  = A[idx];
                tick;
                wr_sel_b = 1'b1;
                wr_data  = B[idx];
            end
            tick;
            wr_en = 1'b0;
        end
    endtask

    task automatic run_and_check;
        input [255:0] name;
        integer ii, jj, kk;
        integer local_err;
        reg done_w;
        reg [15:0] cyc_w;
        begin
            local_err = 0;
            load_matrices();

            tick;
            start = 1'b1;

            // Wait for done (timeout guard)
            cyc_w = 16'd0;
            begin : wait_done
                for (t = 0; t < 500; t = t + 1) begin
                    @(posedge clk);
                    if (N == 4 && done4) begin
                        cyc_w = cycles4;
                        disable wait_done;
                    end
                    if (N == 3 && done3) begin
                        cyc_w = cycles3;
                        disable wait_done;
                    end
                end
                $display("  TIMEOUT waiting for done (%s)", name);
                errors = errors + 1;
            end

            // output_regs captures on done; allow one more edge
            @(posedge clk);
            #1;

            start = 1'b0;
            tick;

            // Compare vs golden C = A * B
            for (ii = 0; ii < N; ii = ii + 1) begin
                for (jj = 0; jj < N; jj = jj + 1) begin
                    exp_c = 0;
                    for (kk = 0; kk < N; kk = kk + 1) begin
                        exp_c = exp_c + A[ii*N + kk] * B[kk*N + jj];
                    end

                    if (N == 4)
                        got_c = c4[ii][jj];
                    else
                        got_c = c3[ii][jj];

                    if (got_c !== exp_c) begin
                        $display("  FAIL %s C[%0d][%0d] got=%0d exp=%0d",
                                 name, ii, jj, got_c, exp_c);
                        local_err = local_err + 1;
                    end
                end
            end

            if (cyc_w !== 3*N) begin
                $display("  FAIL %s latency got=%0d exp=%0d", name, cyc_w, 3*N);
                local_err = local_err + 1;
            end

            if (local_err == 0)
                $display("PASS %-20s  cycles=%0d  (seq baseline %0d -> speed-up %0.2f x)",
                         name, cyc_w, SEQ_LAT, SEQ_LAT * 1.0 / cyc_w);
            else begin
                $display("FAIL %-20s  (%0d mismatches)", name, local_err);
                errors = errors + local_err;
            end

            tests = tests + 1;
        end
    endtask

    task automatic set_identity;
        integer ii, jj;
        begin
            for (ii = 0; ii < N; ii = ii + 1)
                for (jj = 0; jj < N; jj = jj + 1) begin
                    A[ii*N + jj] = (ii == jj) ? 8'sd1 : 8'sd0;
                    B[ii*N + jj] = (ii == jj) ? 8'sd1 : 8'sd0;
                end
        end
    endtask

    task automatic set_zero;
        integer ii;
        begin
            for (ii = 0; ii < N*N; ii = ii + 1) begin
                A[ii] = 0;
                B[ii] = 0;
            end
        end
    endtask

    task automatic set_corner;
        integer ii;
        begin
            for (ii = 0; ii < N*N; ii = ii + 1) begin
                A[ii] = 0;
                B[ii] = 0;
            end
            A[0]         = 8'sd127;
            A[N*N - 1]   = -8'sd128;
            B[0]         = 8'sd127;
            B[N*N - 1]   = -8'sd128;
            // Fill a simple pattern for remaining
            for (ii = 1; ii < N*N - 1; ii = ii + 1) begin
                A[ii] = $signed(ii[7:0]);
                B[ii] = -$signed(ii[7:0]);
            end
        end
    endtask

    task automatic set_random;
        integer ii;
        begin
            for (ii = 0; ii < N*N; ii = ii + 1) begin
                A[ii] = $signed($urandom_range(0, 255) - 128);
                B[ii] = $signed($urandom_range(0, 255) - 128);
            end
        end
    endtask

    task automatic run_suite;
        input integer n_set;
        integer r;
        begin
            N       = n_set;
            SEQ_LAT = N*N*N + 1;
            $display("\n======== Suite N=%0d  (expect latency %0d, seq %0d) ========",
                     N, 3*N, SEQ_LAT);

            apply_reset();
            set_identity();
            run_and_check("identity");

            set_zero();
            run_and_check("zero");

            set_corner();
            run_and_check("corner");

            for (r = 0; r < 20; r = r + 1) begin
                set_random();
                // Name shows random index for log readability
                run_and_check("random");
            end
        end
    endtask

    initial begin
        errors = 0;
        tests  = 0;
        seed   = 32'hC0FFEE;
        // $urandom seed
        void'($urandom(seed));

        $dumpfile("sim/tb_systolic.vcd");
        $dumpvars(0, tb_systolic);

        run_suite(4);
        run_suite(3);

        $display("\n============================================================");
        if (errors == 0)
            $display("*** tb_systolic: ALL %0d TESTS PASSED ***", tests);
        else
            $display("*** tb_systolic: %0d ERROR(S) in %0d tests ***", errors, tests);
        $display("============================================================\n");

        $finish;
    end

endmodule
