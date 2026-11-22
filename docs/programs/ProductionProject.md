# `production_project.py` and sharded execution

**Installed version referenced:** v1.2.2 maintenance, based on v1.2.1 used for the completed 100k run. Orchestration only; physics algorithms unchanged.

## Responsibilities

`production_project.py` is the user-facing controller for independently configured MTAS projects. It creates editable project configs, freezes reproducible runs, validates metadata, submits scheme generation and dependent shard arrays, inspects progress, and explicitly retries disjoint failed shards. Internally, `production_shard.py` runs `campaign_driver.py run --case-id N --until ...` for each assigned case, with up to `workers` independent processes inside a **single allocated CPU node**. The `production_scheme_index.py` SQLite index avoids repeatedly parsing the entire global scheme list for each of 100,000 case processes while preserving SHA-256 checks.

## Commands and behavior

| Command | Required flags | Important optional flags | Behavior |
|---|---|---|---|
| `create` | `--tree`, `--project-dir` | `--from-config DIR` | Create a *new* project with independent copies of 6 INIs; refuses an existing directory. |
| `preflight` | `--tree`, `--project-dir` | — | Check configuration, paths, shard count, active Scratch library, contaminant files and resource syntax. |
| `freeze` | `--tree`, `--project-dir` | `--run-id run_0001` | Create an immutable run; copy six INIs, stage inputs, snapshot SHA-256 of config and orchestration, define shards. |
| `submit` | `--run-dir RUN` | `--shards LIST`, `--dry-run` | `sbatch` for schemes and a dependent `--array 0-(nshards-1)%max_active_nodes` for selected shards; schemes-only produces no array. For ≥10,000 cases explicit initial selection is mandatory (except schemes-only). |
| `status` | `--run-dir RUN` | — | Print scheme/shard status and failed IDs. |
| `resume` | `--run-dir RUN`, `--shards LIST` | `--retry-failed`, `--dry-run` | Explicit retry of selected shards, excluding verified passed shards. |
| `complete-submission` | `--run-dir RUN` | `--dry-run` | Resume a partially completed **submission**, not a scientific stage, without duplicating a scheme job. |

## INI scopes

`Campaign.ini [campaign] scope=` accepts **`schemes`**, **`response`**, **`physical`**, **`full`**. The current controller always prepares a schema-2 run, so its structural preflight expects an existing decay XML, background, and central-correction file even in partial scopes. `SortResponse` on a preexisting raw ROOT tree is a separate standalone task, not a mode of `Campaign.ini`.

- `schemes`: generate variation XML, no response shards or full-case ROOT expectations.
- `response`: response/direct sorting, retain `intermediate.root`.
- `physical`: response + cleaned physical file, **retain intermediate** for partial scope.
- `full`: response + clean physical + ML preprocessing + validation. **Delete intermediate only after successful validation.**

## Shard sizing and execution

If `cases=N` and `shard_size=S`, the controller generates `ceil(N/S)` consecutive **nonoverlapping** case ranges. An array task receives `SLURM_ARRAY_TASK_ID` and processes only its assigned range, with `workers=W<=256`. `max_active_nodes=M` caps simultaneously eligible array tasks using Slurm's `%M` throttle. `scheme_walltime` and `shard_walltime` are distinct Slurm limits, and their values should be chosen from measured real workloads.

Example: `cases=100000`, `shard_size=1024` → 98 shards (last 672 cases), `workers=256`, `max_active_nodes=4`. A runtime Slurm throttle override changes scheduling only; case ranges remain frozen. See [measured results](../guides/PerformanceAndStorage.md).

## Data integrity

`project_run.json` stores a SHA-256 hash for each frozen INI, plus hashes of the controller/orchestration programs. `inputs_manifest.json` records the staged input provenance. Source-aware event contaminant files are included in input fingerprints; the entire 296-GiB response library is referenced from Scratch rather than hashed on every case. The per-case engine records commands, seeds, time and result hashes. Normal `submit` refuses a second submission of the same run; use explicitly selected `resume`/`complete-submission` for recovery.

## Outputs and evidence

```text
PROJECT/config/                         independent editable scientific/operational INIs
PROJECT/runs/run_0001/config/           frozen configuration
PROJECT/runs/run_0001/jobs/production_plan.json
PROJECT/runs/run_0001/jobs/{}           Slurm logs, submissions.jsonl, shard JSON, scheme index
PROJECT/runs/run_0001/schemes/          variation XML
PROJECT/runs/run_0001/cases/            per-case logs, stage statuses, ROOT outputs
PROJECT/runs/run_0001/reports/          campaign_metrics.py outputs
```

Real production: all 100,000 cases passed with v1.2.1. v1.2.2 passed 30 Python tests and preserved modular tests on NERSC; live four-case acceptance is pending. Fixed-reference scientific validation remains separate.

Related [operator guide](../guides/NewCampaign.md), [job status](../guides/CheckingJobs.md), [recovery](../guides/Recovery.md), [production planning](../guides/Production100k.md).
