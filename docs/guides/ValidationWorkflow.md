# Guide: validate results before scaling

Validation has at least three distinct meanings: **program execution success**, **numerical/internal consistency**, and **scientific agreement with a trusted reference**. Only the first two are covered by the default per-case validator.

## 1. Completion and provenance

For every expected case, inspect `response_status.json`, `clean_status.json`, `preprocess_status.json`, `validate_status.json`, and `validation.json`. The completed stages must report success and the input/binary fingerprints must remain intact. Slurm `COMPLETED` means a batch script exited successfully; it is not by itself a validated physics result.

A completed schema-2 case retains `physical.root`, `ml.root` and metadata, and normally has **no** `intermediate.root`. Verify `response_status.json` records `deleted_after_validation` rather than inferring that a missing file was properly removed.

## 2. Numerical invariants

The supplied `scripts/validate_case.py` checks the compact ROOT structures and mathematical consistency. At minimum, inspect:

- Physical *linear-count* `final` equals the sum of its already weighted elementary components binwise for `3300`, `3350`, `3351`, `energyTime`.
- Shared-log final 2D families have valid finite ranges and only the final histogram reaches one when nonzero.
- The shared-log inverse restores physically meaningful densities/counts; **do not add log-transformed components directly**.
- `final/decaySchemeMatrix` is the untransformed β-feeding × first-γ probability matrix, integral approximately one.
- No negative/nonfinite physical cells, missing components, missing output families or unexpected underflow policies.

A simple standalone validation command for complete physical and ML files is:

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2  # use original installation for old-run controller commands
export PY=/global/common/software/gen0018/mtas/root-env/bin/python3
"$PY" "$TREE/scripts/validate_case.py" \
  --physical /absolute/path/to/physical.root \
  --ml /absolute/path/to/ml.root \
  --report /absolute/path/to/validation.json
```

## 3. Scientific reference regression

Compare a **fixed input and seeds** with previously trusted spectra at the same detector thresholds, correction, calibration/resolution settings, pileup/background sample, source fractions and bin edges. Explicitly examine high-energy tails, beta gate efficiency, central/IMO coincidence and escape behavior, contaminant scaling, time evolution and matrix path probabilities.

The verified schema-2 one-case pilot demonstrated mathematical additivity and deletion/restart behavior; it did **not** replace a fixed-reference physics-regression campaign. Mark that gate passed only after the actual comparison has been performed.

## 4. Scaling acceptance

For 16, 64 and 1,024 cases, record the **requested** case count, distinct completed case IDs, failure list, elapsed allocation time, stage timing percentiles, peak memory, node-hours, size distributions, inode consumption and deliberate restart test. The existing controlled ¹³⁶I comparison favored 256 workers per Perlmutter CPU node; confirm this under the current full workload rather than blindly reusing its throughput number.

For future campaigns, consider rehearsing an interrupted node/shard and its restart under the new multi-node scheduler. Validate that all completed cases are skipped, failed cases retain diagnostic intermediate files and no two workers can claim the same case.

See [current readiness](../development/ProductionReadiness.md), [performance and storage](PerformanceAndStorage.md), and [output reference](../reference/OutputFormats.md).

## 5. Reasonable final integrity acceptance

For the completed 100k dataset, all controller shards passed, zero failures/pending, successful Slurm tasks, full scheme-index verify, and a reproducible small sample of readable ROOTs were checked. Expected keys, finite histogram summaries and nonempty content are useful checks. The actual 32-file physical sample passed; 20 histograms each. These checks complement—not replace—the controller per-case validator. Do not reopen 100k ROOTs solely to repeat validated stages. A deeper scan or fixed-seed comparison is appropriate when investigating a discrepancy.
