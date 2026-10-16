# Waveform verification guide (GTKWave)

```bash
make test
make show_pe         # or show_systolic / show_compare
# equivalent: gtkwave waveforms/tb_systolic.vcd &
```

## Signed data viewing

1. Select the buses you care about (`a_in`, `b_in`, `c_out`, …).
2. Right-click → **Data Format → Signed Decimal**.
3. Optional Q-format: **Data Format → Fixed Point Shift → Specify**
   (operands here are signed INT8 / INT32 — signed decimal is usually enough).

## Signals for “correct data propagation”

| Signal | What to look for |
|--------|------------------|
| `u_ctrl.state` | IDLE → CLEAR → RUN → DONE |
| `u_ctrl.a_west[0..N-1]` | A rows enter with row skew |
| `u_ctrl.b_north[0..N-1]` | B cols enter with col skew |
| PE(0,0) `c_out` | Accumulates first |
| PE(N-1,N-1) `c_out` | Corner finishes last |
| `done` / `cycle_count` | `done` when count = 3N |

## PE TB screenshots

`waveforms/tb_pe.vcd` — show `a_in`, `b_in`, `enable`, `clear`, `c_out` for:

- 3 × 4 → 12  
- −2 × 5 → −10  
- 127 × 127 → 16129  
- −128 × −128 → 16384  

## Optional `.gtkw` save file

After arranging signals once, **File → Write Save File** as
`waveforms/tb_systolic.gtkw`. Next time:

```bash
gtkwave waveforms/tb_systolic.vcd waveforms/tb_systolic.gtkw &
```
