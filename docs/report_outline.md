# Final report outline (draft)

1. **Introduction** — matrix multiply in ML/DSP; why spatial / systolic arrays.
2. **Related work** — Gemmini (OS/WS), SCALE-Sim; briefly note WS vs OS trade-off.
3. **Architecture** — output-stationary choice; PE; skew; FSM; hierarchy diagram.
4. **Implementation** — fixed-point widths; parameters N=3/4; module list.
5. **Verification** — PE cases; golden model; waveforms.
6. **Results** — latency, throughput, speed-up vs sequential, PE utilization.
7. **FPGA synthesis** — resources, Fmax (fill from Vivado).
8. **Discussion** — OS vs WS utilization; area–speed trade-off (16 DSPs vs 1).
9. **Conclusion** — demo notes and future work (tiling, AXI).
