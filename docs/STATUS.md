# Project status

## Done (simulation)

- [x] Modular synthesizable RTL (8 modules)
- [x] PE / MAC directed testbench — 21/21 pass
- [x] System TB: identity, zero, corner, 20 random × {3×3, 4×4} — 46/46 pass
- [x] Sequential baseline compare — 12 vs 65 cycles, **5.42×** speed-up
- [x] VCD dumps under `sim/` and `waveforms/`
- [x] Architecture write-up (`docs/architecture.md`)
- [x] Related work notes (`docs/related_work.md`)
- [x] README + `make show_*` GTKWave workflow
- [x] `make test` flow
- [x] Demo testbench `tb/tb_demo.v` + `make demo`
- [x] Block diagram figure (`docs/figures/block_diagram.png`)
- [x] Waveform figure of A/B skew from VCD (`docs/figures/waveform_demo.png`)
- [x] GTKWave save file `waveforms/tb_demo.gtkw` + screenshot `docs/figures/gtkwave_demo.png`
- [x] Ports and parameters of every module (`docs/architecture.md`)
- [x] Paper notes with links (`docs/related_work.md`)
- [x] Yosys estimate for one PE (`syn/pe_xc7_stat.txt`)
- [x] IEEE Phase I report (`docs/phase1/IEEE_Phase1_Report.pdf`)

## Remaining (demo / report / FPGA) — lab / write-up only

- [x] Phase I demo video link in README
- [ ] Vivado synthesis: LUT / FF / DSP + Fmax (lab PC) — Phase II
- [ ] Scaling study (more N), back-to-back matrices — Phase II
- [ ] Final IEEE report (Results, Discussion, Conclusion) — Phase II

Loop stopped: local RTL/sim/docs are complete; remaining items need lab tools or human write-up.

## Commands

```bash
make test
```
