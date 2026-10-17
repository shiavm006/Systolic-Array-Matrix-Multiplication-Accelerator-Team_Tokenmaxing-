# Systolic Array Matrix Multiplication Accelerator

A minimal **output-stationary** systolic array for \(C = A \times B\), sized
for a B.Tech FPGA / HDL project (N = 3 or 4, signed INT8 × INT8 → INT32 accum).

## Table of contents

1. [Motivation](#motivation)
2. [Architecture (short)](#architecture-short)
3. [Results](#results)
4. [Project layout](#project-layout)
5. [Setup](#setup)
6. [Running tests](#running-tests)
7. [Waveforms (GTKWave)](#waveforms-gtkwave)
8. [FPGA / Vivado](#fpga--vivado)
9. [Report docs](#report-docs)

## Motivation

Matrix multiply dominates ML and DSP kernels. A systolic array turns that into
local PE-to-PE communication instead of one shared multiplier. This project
builds a small, explainable array, proves it against a golden model, and
compares latency to a sequential baseline.

## Architecture (short)

| Block | Role |
|-------|------|
| **PE** | MAC every enabled cycle; pass `a` east and `b` south; keep \(C_{ij}\) |
| **Systolic array** | N×N mesh of PEs |
| **Controller** | FSM `IDLE → CLEAR → RUN → DONE` + skewed feed of A/B |
| **Input buffers** | Scratchpads for A and B |
| **Output regs** | Capture C when `done` |
| **seq_matmul** | One-MAC-per-cycle baseline |

Dataflow: **A** left→right, **B** top→bottom, **C** stationary in the PE
(output-stationary). Full detail: [docs/architecture.md](docs/architecture.md).

## Results

| Metric (N=4) | Value |
|--------------|-------|
| Latency | 12 cycles (= 3N) |
| Sequential baseline | 65 cycles (= N³+1) |
| Speed-up | **5.42×** |
| Throughput | ~5.33 MACs/cycle vs ~0.98 |
| PE utilization | ~33% (OS fill/drain — expected) |

| N | Systolic | Sequential | Speed-up |
|---|----------|------------|----------|
| 3 | 9 | 28 | 3.11× |
| 4 | 12 | 65 | 5.42× |

Simulation: PE directed tests + 46 system cases (identity / zero / corner /
20 random × {3×3, 4×4}) + systolic-vs-sequential compare — all pass.

## Project layout

```
rtl/          synthesizable Verilog
tb/           PE, system, compare testbenches
sim/          compiled sims + fresh VCDs
waveforms/    copied VCDs for GTKWave / screenshots
docs/         architecture, related work, Vivado, report outline
Makefile      make test | pe | systolic | compare | show_*
```

## Setup

Needs **Icarus Verilog** (`iverilog`, `vvp`). Optional: **GTKWave**.

```bash
# macOS
brew install icarus-verilog
# optional: brew install --cask gtkwave

# Ubuntu
sudo apt install iverilog gtkwave
```

## Running tests

```bash
make test          # pe + systolic + compare
make pe            # PE / MAC directed cases
make systolic      # full array vs golden model
make compare       # systolic vs sequential on same matrices
```

## Waveforms (GTKWave)

After `make test`, VCDs are also copied to `waveforms/`:

```bash
make show_pe
make show_systolic
make show_compare
```

In GTKWave:

1. Select signals → **Data Format → Signed Decimal**
2. Optional: **Fixed Point Shift** if you present Q-format in the report

Signal checklist: [docs/waveform_guide.md](docs/waveform_guide.md).

## FPGA / Vivado

Lab PC steps for LUT/FF/DSP and Fmax:
[docs/vivado_checklist.md](docs/vivado_checklist.md).

## Report docs

| Doc | Purpose |
|-----|---------|
| [docs/architecture.md](docs/architecture.md) | Block diagram, FSM, metrics |
| [docs/related_work.md](docs/related_work.md) | Dataflow context (Gemmini, SCALE-Sim) |
| [docs/report_outline.md](docs/report_outline.md) | Final report skeleton |
| [docs/STATUS.md](docs/STATUS.md) | Done vs remaining for submission |
