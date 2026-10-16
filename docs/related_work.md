# Related work (for report / viva)

RTL and testbenches in this repository are an original output-stationary
design. The notes below are only for **citing concepts** in the report.

## Dataflow context

Spatial / systolic accelerators commonly use one of:

- **Weight-stationary (WS)** — weights stay in the PE; often high steady-state
  PE utilization when the same weights are reused.
- **Output-stationary (OS)** — each PE owns one \(C_{ij}\) (this project).
- **Input-stationary (IS)** — less common in small teaching arrays.

Berkeley **Gemmini** can be configured for OS or WS (and related modes), which
shows that output-stationary is a legitimate design choice, not a shortcut.
**SCALE-Sim** is useful if you want an independent cycle / utilization model
to compare against your measured 3N latency and ~33% PE use on 4×4.

### Trade-off to state clearly

| | Typical WS | This project (OS) |
|---|---|---|
| What stays in the PE | Weight | Partial sum \(C_{ij}\) |
| Steady-state PE use | Often high once the pipeline is full | ~33% on 4×4 (fill/drain) |
| Natural fit | Reuse same weights many times | One C tile while streaming A and B |

Lower OS utilization is expected; explain fill/drain rather than hiding it.

## Suggested citation sentence

> The accelerator implements an original output-stationary N×N systolic array
> with a sequential MAC baseline for speed-up comparison. Configuration options
> in spatial-array generators such as Gemmini, and cycle models such as
> SCALE-Sim, were consulted only for architectural context.
