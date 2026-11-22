> **Historical record:** earlier source/benchmark review and then-current open questions. For current status see [production readiness](../development/ProductionReadiness.md) and [100k results](../guides/Production100k.md).

**Compatibility note:** This is the historical single-node packed launcher. For new multi-node projects use [Create a new campaign](NewCampaign.md) and the production shard controller, which is installed and was tested with 512 cases across two nodes. See [Job status](CheckingJobs.md).

# Packed workers on a Perlmutter CPU node

## Status and baseline

**Provisional production baseline: 256 processes per CPU node.** This is grounded in an actual *controlled same-schemes* comparison of 1,024 randomized **136I** schemes supplied by the project researcher:

| Measurement | 128 workers | 256 workers |
|---|---:|---:|
| Cases | 1,024 | 1,024 |
| Node allocation time | 311.56 s | 232.01 s |
| Throughput | 11,832 cases/node-hour | 15,889 cases/node-hour |
| Mean case time | 37.34 s | 54.54 s |
| Median case time | 31.28 s | 46.01 s |
| Mean S+S / S+B pileup | 0.70 / 0.76 s | 0.88 / 0.93 s |
| Mean peak resident memory | 982 MB | 974 MB |

For this controlled 136I benchmark, 256 workers improved throughput **34.3%** and cut node-hours **25.5%**. The goal is cases **per node-hour**, not fastest individual case. This is a proven comparison **for that workload**, not a measured projection for the newer full **92Y + 92Sr** response/cleanup/ML/validation pipeline.

Perlmutter CPU nodes provide 128 physical cores / 256 logical CPUs (2 threads/core) and 512 GB RAM. We use a *single* CPU-node allocation with `--cpus-per-task=256 --hint=multithread` and launch up to 256 independent subprocesses inside it. See official NERSC architecture and affinity documentation.

## One canonical installation

Two additional executable files belong in the **existing** project:

- `scripts/packed_campaign.py` — guarded worker-pool orchestrator; invokes existing `campaign_driver.py` with `--until schemes` once, then per-case `--case-id` commands with bounded concurrency.
- `jobs/packed_campaign.slurm` — requests **one** Perlmutter CPU node for the pool. Worker count defaults to 256 and can be reduced using `MTAS_WORKERS`.

The `tests/integration/test_packed_campaign.py` file checks independent case execution and failure reporting. No C++ or established campaign-driver source is modified.

## Pilot and scaling sequence

Keep the previously submitted 16-case four-node array running as an integration/individual-timing sample; **do not use it to evaluate node-hour efficiency**. The new packed launcher is for later campaigns.

First initialize a **new** schema-2 campaign with the canonical driver, as usual, using the correct Scratch response library, MTASBKG1 background, central correction and mixture file. Do **not** set `--keep-intermediate`.

Inspect before submission:

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation
export RUN=/pscratch/sd/m/michals/MTAS/production/campaign_scaling_64_packed_v1
python3 "$TREE/scripts/packed_campaign.py" --run-dir "$RUN" --workers 64 --dry-run
python3 "$TREE/scripts/campaign_driver.py" plan --run-dir "$RUN" --audit
```

For 64 cases, submit a single node with 64 active workers:

```bash
sbatch -A gen0018 --time=00:45:00 \
  --output="$RUN/packed-%j.out" --error="$RUN/packed-%j.err" \
  --export=ALL,MTAS_CAMPAIGN_RUN="$RUN",MTAS_TREE="$TREE",MTAS_WORKERS=64 \
  "$TREE/jobs/packed_campaign.slurm"
```

The allocation still reserves 256 logical CPUs; 64 independent cases are a smoke test, **not** a saturated 256-worker benchmark.

After the 64-case run and a fixed-reference physics check, use a **new** 1,024-case campaign with `MTAS_WORKERS=256` and a wall limit based on measured times. Consider an additional 1,024-case run with **128 workers and the same master seed and source inputs** (in its own new campaign directory), to compare throughput under the *current full-pipeline workload*. The earlier 136I result remains the provisional baseline.

## Measurements

The launcher writes:

- `$RUN/jobs/packed_summary.json`: single-node measured end-to-end allocation wall, case-phase wall, completed cases, failure list, and **cases per node-hour**.
- `$RUN/jobs/logs/packed_schemes.log` and `case_NNNNNN.log`: full stdout/stderr for scheme generation and each case driver.
- `$RUN/jobs/metrics/schemes.time.txt` and `case_NNNNNN.time.txt` (when `/usr/bin/time` is available): worker wall, user/system CPU, peak RSS.
- Canonical `$RUN/cases/case_NNNNNN/{response,clean,preprocess,validate}_status.json`: existing *individual stage* times, outputs and hashes.

For disk and inode accounting, run the existing `MTAS_Scaling_Test16_v1/scripts/campaign_metrics.py` against the new campaign. The final expected case outputs remain **physical.root** and **ml.root**; the intermediate is disposed **only after validation**.

Do not infer 100,000-case runtime directly from the older 136I benchmark or from single-process 92Y timing. Use current-workload cases/node-hour, memory, and storage measured in the packed 1,024-case run.

## Safety and performance constraints

1. Do not run this launcher concurrently with another campaign launcher in the same directory. A campaign-level `flock` blocks a second packed launcher.
2. No automatic `--retry-failed`: review failed-case logs before opting into explicit retries.
3. One thread per worker (`OMP_NUM_THREADS=1` and common BLAS thread limits). The existing physics binaries and their random seeds are unchanged.
4. The driver may repeatedly hash sizeable input files, including the experimental background and contaminant ROOT files. At 256-way concurrency, this could be a substantial shared-file I/O cost. Measure it; optimize carefully without weakening input integrity.
5. 256 workers use the two hardware threads of each core. Older 136I measurements show higher throughput despite longer individual case runtimes, but **memory and filesystem contention can differ** for 92Y+92Sr.
6. Slurm `--time` remains configurable on submission. Avoid hard-coding a 10-minute time limit for 1,024 cases before measuring the packed run.
7. For 100,000 cases, also account for generated XML files, per-case logs/status/config, temporary files of in-flight workers and inodes. A 20 TiB capacity does not guarantee retention: Scratch is purgeable and not backed up.

## Prior separate array launcher

The `MTAS_Scaling_Test16_v1` launcher allocated a separate node for each array task (four active nodes, one worker per node). This was an unsuitable node-efficiency design. Preserve its results as a correctness/latency sample only; do not use its concurrency projections for production scheduling.
