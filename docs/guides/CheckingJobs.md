# Check the status of jobs and MTAS campaigns on NERSC

This is the general reference for every guide that ends with a Slurm submission. **Slurm job state** and **scientific campaign state** are separate: a job may finish successfully without every desired case passing validation, and a previously failed job may leave many valid cases that must not be regenerated.

## 1. Check your current queue

```bash
squeue -u "$USER"
```

`ST` is commonly `PD` (pending) or `R` (running). Completed jobs disappear from `squeue`, not necessarily from the accounting records. An array may be displayed as one range such as `61596881_[0-1]`; that represents **multiple array tasks**, not one task. To expand array entries:

```bash
squeue -r -j JOB_ID
```

## 2. Check completed jobs and array tasks

```bash
sacct -j JOB_ID \
  --format=JobID%24,JobName%18,State%18,Elapsed,ExitCode,NodeList%20
```

For example, `61596881_0` and `61596881_1` are two different array tasks. A result `COMPLETED` with `ExitCode=0:0` is a successful **process** result, but you must still inspect `production_project.py status` and case `validation.json` files. `*.batch` and `*.extern` rows are Slurm steps and are not extra simulations.

Common states: `PENDING`, `RUNNING`, `COMPLETED`, `FAILED`, `CANCELLED`, `TIMEOUT`, `OUT_OF_MEMORY`. `PD (Priority)` means scheduling priority, `PD (Resources)` means resources unavailable, and `PD (Dependency)` means waiting for a prerequisite job. Slurm can report several reasons, e.g. `Priority,Resources`.

## 3. See why a job is waiting

```bash
squeue -j JOB_ID
squeue --start -j JOB_ID
scontrol show job JOB_ID | grep -E 'JobState=|Reason=|StartTime=|TimeLimit=|Dependency=|QOS='
```

`--start` is a **prediction**, not a reservation; it may show `N/A` or change. For a production run, first the scheme job must complete; only then will the dependent response shard array become eligible for scheduling. A pending reason is not evidence that the physics code failed.

## 4. Inspect the batch output and error logs

Production projects have frozen `RUN/jobs` paths, e.g.:

```bash
export RUN=/pscratch/sd/m/michals/MTAS/production/MyCampaign/runs/run_0001
ls -lh "$RUN/jobs/"
ls -lh "$RUN/jobs/"*.out "$RUN/jobs/"*.err 2>/dev/null
```

Slurm submission records show the actual output path patterns; typical ones are `schemes-%j.out` and `shards-%A_%a.out`. Read recent entries with:

```bash
tail -n 60 "$RUN/jobs/shards-ARRAY_JOB_ID_0.out"
```

To follow a running task:

```bash
tail -f "$RUN/jobs/shards-ARRAY_JOB_ID_0.out"
```

Press `Ctrl+C` to stop `tail`, **not** the Slurm job. Each case also has its own processing log and status JSON; shard summary JSONs are under `RUN/jobs/shards/`.

## 5. Check **MTAS scientific progress**, not just scheduling

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2  # use original installation for old-run controller commands
export PY=/global/common/software/gen0018/mtas/root-env/bin/python3
"$PY" "$TREE/scripts/production_project.py" status --run-dir "$RUN"
```

The production status shows the scheme stage, shard counts, failed IDs, and whether intermediate ROOT files are designed to be retained or cleaned. For detailed per-case stages:

```bash
"$PY" "$TREE/scripts/campaign_driver.py" status --run-dir "$RUN"
```

The canonical case driver tracks `response`, `clean`, `preprocess`, and `validate` separately. A **full** case should have `physical.root`, `ml.root`, `validation.json` and an intentional `deleted_after_validation` intermediate disposition. A partial-scope run is judged by the scope requested, not by the full pipeline's validation requirements.

## 6. Measure compute resources and cost

For a completed Slurm job or array, use:

```bash
sacct -j JOB_ID \
  --format=JobID%22,State%14,Elapsed,AllocCPUS,TotalCPU,MaxRSS,NodeList%20,ExitCode
```

For worker-pool jobs, the `.batch` step may contain the aggregate `MaxRSS`; it is **not automatically** the peak resident memory of one physics process. Inspect the case-level timing reports and note the distinction. Actual **node-hours** should use each allocated node's Slurm `Elapsed` time, summed over array tasks; do **not** add all case wall times and call that node-hours.

To generate campaign metrics *after completion*:

```bash
"$PY" "$TREE/scripts/campaign_metrics.py" \
  --run-dir "$RUN" --require-complete --report-dir "$RUN/reports"
showquota
```

`showquota` reports both Scratch **space** and **inode** limits; monitor both for 100,000-case campaigns. Do not infer free CFS group space from your personal Scratch quota.

## 7. If jobs fail or seem stuck

1. Check `sacct` for `FAILED`, `TIMEOUT`, `OUT_OF_MEMORY`, or exit code; check `squeue` for waiting reasons.
2. Read the exact shard's Slurm output/error and `RUN/jobs/shards/shard_NNNNN.json` plus per-case logs.
3. Confirm a failed job is no longer running **before** retrying it. Running two jobs against the same shard could corrupt outputs.
4. Consult [Recovery](Recovery.md) for `production_project.py resume`, `--retry-failed`, and incomplete submission recovery. Do **not** edit a frozen run or delete successful case outputs.
5. Never assume a `DependencyNeverSatisfied` array will eventually start without action; first diagnose the prerequisite's failed state.

## 8. Where every campaign guide should point

After any `sbatch` or production `submit`, check `squeue`, `sacct`, `production_project.py status`, logs, and finally metrics. This chapter is linked from [new campaigns](NewCampaign.md), [100k run](Production100k.md), [scheme generation](GenerateSchemes.md), [standalone simulation](SimulateFromXML.md), [sorting](SortExistingEvents.md), and [recovery](Recovery.md).

## 9. v1.2.2 reporting tools

Use the original controller for historical run status. The maintained reporter can inspect older runs read-only.

```bash
python3 "$TREE/scripts/campaign_metrics.py" --run-dir "$RUN" --require-complete
python3 "$TREE/scripts/campaign_metrics.py" --run-dir "$RUN" --require-complete --detailed
python3 "$TREE/scripts/production_scaling_report.py" --run-dir "$RUN" --details --report-dir "$RUN/reports/scaling"
```

Default metrics is O(shards), not a recursive scan. Only add `--detailed --scan-storage` when exact storage accounting is required; on a 100k run this is costly. Slurm records have limited retention; archive report JSON and array CSV promptly. For maintenance builds specify absolute `--output="$HOME/name-%j.out"` and `--chdir="$HOME"` to avoid read-only Global Common.
