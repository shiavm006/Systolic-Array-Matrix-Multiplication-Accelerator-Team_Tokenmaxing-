# Systolic Array Matrix Multiplication — Architecture

## Goal

A small **output-stationary** systolic-array accelerator for \(C = A \times B\) with
signed 8-bit operands and 32-bit accumulators. Parameter `N` selects a
**3×3** or **4×4** PE grid (B.Tech-scale FPGA target).

## Why output-stationary?

Each PE owns one \(C_{ij}\) and accumulates all \(k\) products in place.
**A** streams left→right; **B** streams top→bottom, with intentional skew so
\(A_{ik}\) and \(B_{kj}\) meet at PE\((i,j)\).

Many published and teaching arrays use **weight-stationary** dataflow (often
higher steady-state PE utilization). Output-stationary is still a standard
option (e.g. Berkeley Gemmini can be configured OS or WS). The trade-off is
honest: fill/drain leave PEs idle part of the time (~33% utilization on 4×4).
See [related_work.md](related_work.md).

## Block diagram

```
                    wr_en / wr_addr / wr_data
                              |
                              v
                     +------------------+
                     |  input_buffers   |  A[], B[] scratchpads
                     +--------+---------+
                              |
              +---------------v----------------+
              |           controller           |
              |  IDLE -> CLEAR -> RUN -> DONE  |
              |  skewed a_west[] / b_north[]   |
              +-------+--------------+---------+
                      |              |
                      v              v
              +--------------------------------+
              |     systolic_array (N x N)     |
              |   PE = mac_unit + a/b pipes    |
              +----------------+---------------+
                               |
                               v
                      +----------------+
                      |  output_regs   |  capture C on done
                      +----------------+
```

## PE microarchitecture

On each enabled cycle:

- \(C \leftarrow C + a_{in} \times b_{in}\) (MAC)
- \(a_{out} \leftarrow a_{in}\), \(b_{out} \leftarrow b_{in}\) (systolic pipes)

`clear` zeros the accumulator (CLEAR state).

## Controller schedule

Injection at boundary time \(t\):

- west\([i] \leftarrow A[i][k]\) when \(t = i + k\)
- north\([j] \leftarrow B[k][j]\) when \(t = j + k\)

Meeting time at PE\((i,j)\): \(r = i + j + k\).
Last MAC: \(r = 3N - 3\). RUN window: \(3N - 2\) cycles.
**start → done latency = \(3N\)** (12 for \(N=4\), 9 for \(N=3\)).

## Baseline comparison

`seq_matmul`: one MAC per cycle → latency \(N^3 + 1\) (65 for \(N=4\)).

| N | Systolic | Sequential | Speed-up |
|---|----------|------------|----------|
| 3 | 9        | 28         | 3.11×    |
| 4 | 12       | 65         | 5.42×    |

Throughput (4×4): \(64\) MACs / \(12\) cycles ≈ **5.33 MACs/cycle**
vs sequential ≈ **0.98 MACs/cycle**.

PE utilization ≈ \(5.33 / 16 ≈ 33\%\) (fill/drain tax — expected for OS).

## Module list

| Module            | Role                                      |
|-------------------|-------------------------------------------|
| `mac_unit.v`      | Combinational signed MAC                  |
| `pe.v`            | Output-stationary PE                      |
| `systolic_array.v`| N×N PE mesh                               |
| `controller.v`    | FSM + skew feeder                         |
| `input_buffers.v` | A/B scratchpads                           |
| `output_regs.v`   | C capture on done                         |
| `systolic_top.v`  | Accelerator top                           |
| `seq_matmul.v`    | Sequential baseline                       |

## Tool flow

Verilog RTL → Icarus (`make test`) → VCD waveforms → Vivado synth
(resources + Fmax on lab FPGA) → report + live demo.
