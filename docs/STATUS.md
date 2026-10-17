# Project status

## Done (simulation)

- [x] Modular synthesizable RTL (8 modules)
- [x] PE / MAC directed testbench — all pass
- [x] System TB: identity, zero, corner, 20 random × {3×3, 4×4} — 46/46 pass
- [x] Sequential baseline compare — 12 vs 65 cycles, **5.42×** speed-up
- [x] VCD dumps under `sim/` and `waveforms/`
- [x] Architecture write-up (`docs/architecture.md`)
- [x] Related work notes (`docs/related_work.md`)
- [x] README + `make show_*` GTKWave workflow
- [x] `make test` flow

## Remaining (demo / report / FPGA) — lab / write-up only

- [ ] GTKWave screenshots of A/B skew (data propagation)
- [ ] Vivado synthesis: LUT / FF / DSP + Fmax (lab PC)
- [ ] Final technical report + live demonstration
- [ ] Optional: block-diagram figure for slides

Loop stopped: local RTL/sim/docs are complete; remaining items need lab tools or human write-up.

## Commands

```bash
make test
```
