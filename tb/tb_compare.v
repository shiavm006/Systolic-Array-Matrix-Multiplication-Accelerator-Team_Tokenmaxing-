//==============================================================================
// tb_compare.v
// Side-by-side systolic vs sequential baseline on the same matrices.
//==============================================================================

`timescale 1ns / 1ps

module tb_compare;

    localparam integer N      = 4;
    localparam integer DATA_W = 8;
    localparam integer ACC_W  = 32;

    reg clk, rst_n, start;
    reg wr_en, wr_sel_b;
    reg [$clog2(N*N)-1:0] wr_addr;
    reg signed [DATA_W-1:0] wr_data;

    wire done_sys, done_seq;
    wire [15:0] cyc_sys, cyc_seq;
    wire signed [ACC_W-1:0] c_sys [0:N-1][0:N-1];
    wire signed [ACC_W-1:0] c_seq [0:N-1][0:N-1];

    wire signed [DATA_W-1:0] a_mem [0:N*N-1];
    wire signed [DATA_W-1:0] b_mem [0:N*N-1];

    integer i, j, errors;

    input_buffers #(.N(N), .DATA_W(DATA_W)) u_buf (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_sel_b(wr_sel_b),
        .wr_addr(wr_addr), .wr_data(wr_data),
        .a_mem(a_mem), .b_mem(b_mem)
    );

    systolic_top #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) u_sys (
        .clk(clk), .rst_n(rst_n), .start(start),
        .wr_en(wr_en), .wr_sel_b(wr_sel_b),
        .wr_addr(wr_addr), .wr_data(wr_data),
        .done(done_sys), .cycle_count(cyc_sys), .c_out(c_sys)
    );

    seq_matmul #(.N(N), .DATA_W(DATA_W), .ACC_W(ACC_W)) u_seq (
        .clk(clk), .rst_n(rst_n), .start(start),
        .a_mem(a_mem), .b_mem(b_mem),
        .done(done_seq), .cycle_count(cyc_seq), .c_out(c_seq)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic tick; begin @(negedge clk); end endtask

    initial begin
        errors = 0;
        rst_n = 0; start = 0; wr_en = 0; wr_sel_b = 0; wr_addr = 0; wr_data = 0;
        $dumpfile("sim/tb_compare.vcd");
        $dumpvars(0, tb_compare);

        repeat (4) tick;
        rst_n = 1;
        tick;

        // Load A = [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16]]
        //      B = identity-ish pattern
        for (i = 0; i < N*N; i = i + 1) begin
            tick;
            wr_en = 1; wr_sel_b = 0; wr_addr = i[$clog2(N*N)-1:0];
            wr_data = i[DATA_W-1:0] + 1;
            tick;
            wr_sel_b = 1;
            // B = I
            wr_data = ((i / N) == (i % N)) ? 8'sd1 : 8'sd0;
        end
        tick; wr_en = 0;

        tick; start = 1;

        // Wait until both done
        begin : wait_both
            integer t;
            for (t = 0; t < 500; t = t + 1) begin
                @(posedge clk);
                if (done_sys && done_seq) disable wait_both;
            end
        end
        @(posedge clk); #1;

        $display("Systolic  cycles = %0d", cyc_sys);
        $display("Sequential cycles = %0d", cyc_seq);
        $display("Speed-up          = %0.2f x", cyc_seq * 1.0 / cyc_sys);

        for (i = 0; i < N; i = i + 1)
            for (j = 0; j < N; j = j + 1)
                if (c_sys[i][j] !== c_seq[i][j]) begin
                    $display("MISMATCH C[%0d][%0d] sys=%0d seq=%0d",
                             i, j, c_sys[i][j], c_seq[i][j]);
                    errors = errors + 1;
                end

        if (cyc_sys !== 16'd12 || cyc_seq !== 16'd65) begin
            $display("FAIL unexpected latencies sys=%0d seq=%0d", cyc_sys, cyc_seq);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("\n*** tb_compare: PASS (results match, 65/12 = 5.42x) ***\n");
        else
            $display("\n*** tb_compare: %0d FAIL ***\n", errors);

        $finish;
    end

endmodule
