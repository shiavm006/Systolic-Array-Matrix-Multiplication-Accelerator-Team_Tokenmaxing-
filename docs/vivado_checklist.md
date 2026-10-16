# Vivado lab checklist (resources + Fmax)

Target top: `systolic_top` with `N=4`, `DATA_W=8`, `ACC_W=32`.

1. Create project → add all files under `rtl/`.
2. Set `systolic_top` as top (or wrap with board I/O if programming FPGA).
3. Run **Synthesis** then **Open Synthesized Design**.
4. Record from **Utilization**:
   - LUTs, FFs, DSPs, BRAMs
5. Run **Implementation** → **Report Timing Summary**:
   - WNS (ns), clock period constraint
   - \(F_{max} \approx 1000 / (T_{clk} - WNS)\) MHz if WNS refers to that clock
6. Optional: generate bitstream for demo board; capture ILA of `a_west`, `b_north`, `done`.

Expected ballpark (varies by part / tool): on the order of **N² DSP48** slices
if multipliers map to DSP (16 for 4×4), plus pipeline FFs for PE a/b/c regs.
