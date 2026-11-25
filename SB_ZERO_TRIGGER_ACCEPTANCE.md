# S+B zero-trigger one-case regression — reported November 24, 2026

Original: `/pscratch/sd/m/michals/MTAS/production/Production_100k_candidate_v1/runs/run_0001/cases/case_000003/outputs/physical.root`

Patched: `/pscratch/sd/m/michals/MTAS/maintenance/sbzero_trial_v1/replayed_case/physical.root`

- Original S+B 3300 fraction: **0.753500%**
- Patched S+B 3300 fraction: **0.753500%**
- Zero-MTAS beta triggers observed: **493803**
- S+B zero-MTAS primary draws: **7075237**
- All bins in `components/main` and `components/pileup_ss` identical for 3300,3350,3351,energyTime.
- All bins in `components/contaminants/Sr92` identical for the same four families.
- Changed S+B bins: `3300` 354; `3350` 62529; `3351` 61015; `energyTime` 125316.
- 3300 S+B signed sum difference is numerical zero (~-2.2e-14); 2D signed differences are nonzero because accepted Y populations can change with the physical shape.
- Report final line: `PASS: S+S/main/contaminants identical; S+B modified; 3300 fraction fixed`.

This is an operator-reported, one-case **scientific regression**, not evidence that permanent v1.2.3 Global Common deployment or independent multi-case project-controller acceptance has already completed.
