# Inspect campaign products, metadata and validation

## 1. Locate a specific frozen run and case

For the installed production controller:

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2  # use original installation for old-run controller commands
export PY=/global/common/software/gen0018/mtas/root-env/bin/python3
export PROJECT=/pscratch/sd/m/michals/MTAS/production/MyCampaign
export RUN="$PROJECT/runs/run_0001"
export CASE="$RUN/cases/case_000000"
```

The project root `config/` is editable; the run's `config/` is the frozen scientific record. Expected structure:

```text
PROJECT/
  config/                         # independent editable INIs
  runs/run_0001/
    project_run.json              # config and orchestration SHA-256
    campaign.json                 # case seeds and runtime snapshot
    inputs_manifest.json          # staged file locations and hashes
    config/                       # frozen source INIs
    schemes/scheme_000000/        # Decay.xml, Parent.xml, Daughter.xml
    scheme_status.json
    jobs/
      production_plan.json        # case count, workers, shard ranges
      submissions.jsonl           # Slurm job IDs and dependencies
      scheme_index.sqlite         # fast verified scheme lookup
      shards/shard_00000.json     # shard outcome
      shards-<ARRAY>_<TASK>.out   # Slurm standard output
    cases/case_000000/
      config/                     # effective per-case settings/seeds
      logs/                       # source and stage logs
      response_status.json        # includes intermediate disposition
      clean_status.json
      preprocess_status.json
      validate_status.json
      validation.json
      outputs/physical.root       # for clean/full scopes
      outputs/ml.root             # for full scope
      # outputs/intermediate.root deliberately absent after full validation
    reports/                      # metrics.json and case_metrics.csv after report
```

`scope=schemes` creates only scheme outputs; `response`/`physical` retain their intermediate ROOT by design. Never assume the full-scope files must exist in a partial run.

## 2. Check scientific campaign and job states

```bash
"$PY" "$TREE/scripts/production_project.py" status --run-dir "$RUN"
"$PY" "$TREE/scripts/campaign_driver.py" status --run-dir "$RUN"
```

The first shows schemes and shard summaries; the second shows per-stage success/fail/running/pending counts. For Slurm completion status, queue, array members, node IDs, memory and elapsed see [Checking jobs](CheckingJobs.md). **Slurm `COMPLETED` does not alone prove `validation.json` passed.**

## 3. Inspect a case's scientific checks

```bash
"$PY" -m json.tool "$CASE/validation.json" | head -100
"$PY" -m json.tool "$CASE/response_status.json" | tail -50
ls -lh "$CASE/outputs"
```

A valid **full** case has `validation.json: passed=true`, physically weighted elementary components summing binwise to `final`, `ml.root` families with a shared-log transform, and `final/decaySchemeMatrix` normalized to 1. `response_status.json` records the intermediate's original hash and a `deleted_after_validation` disposition. This is **not** a missing-file error.

## 4. Inspect ROOT paths and transform metadata

```bash
root -l "$CASE/outputs/physical.root"
# In ROOT:
# .ls
# final/3300; final/3350; final/3351; final/energyTime
```

Physical components are `components/main`, `components/contaminants/<NAME>`, `components/pileup_ss`, and `components/pileup_sbkg`, each with `3300`, `3350`, `3351`, `energyTime`. They already have **correct physical amplitudes**. The compact file contains only final and elementary weighted groups, not redundant aggregates.

`ml.root` contains transformed 3350/3351/energyTime families, the untransformed probability matrix and `metadata/Transform_3350`, `Transform_3351`, `Transform_energyTime`. For exact physical reconstruction from logged components, see [Normalization and reconstruction](../physics/NormalizationAndReconstruction.md) and its [read-only Python script](../examples/ReconstructML.py).

## 5. Generate a cross-case performance and storage report

After a full campaign has finished:

```bash
"$PY" "$TREE/scripts/campaign_metrics.py" \
  --run-dir "$RUN" --require-complete --report-dir "$RUN/reports"
showquota
```

`reports/metrics.json` and `reports/case_metrics.csv` report time distributions, known process RSS, output bytes and inode counts. For total node-hours use the **Slurm allocation elapsed per array task** (`sacct`), not the sum of overlapping per-case `wall_seconds`. The metrics command's hypothetical 100,000-case estimates are not scheduling predictions.

For scientific model interpretation see [Pileup](../physics/PileupDetailed.md), [Time evolution](../physics/TimeEvolutionDetailed.md), and [Output reference](../reference/OutputFormats.md).
