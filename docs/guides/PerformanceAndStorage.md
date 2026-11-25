# Performance, memory and storage — measured MTAS campaigns

This guide distinguishes **case stage wall time**, **whole-node allocation elapsed**, **node-hours**, **Slurm queue delay**, and **disk/inode space**. They are not interchangeable. Prefer measurements from a validated full-pipeline workload at the intended simultaneous node/worker configuration.

## Completed production campaign (November 20–21, 2026)

Full 92Y+92Sr, 1M events/case, 256 workers/node, 1,024 cases/shard (last shard 672). All 98 shards passed. Slurm elapsed time is measured from earliest start to latest end for each tranche, excluding waiting before first start. Node-hours are summed allocated task seconds/3600; each task uses one node. Code was v1.2.1 with the same physics as v1.2.2. **v1.2.3 deliberately changes S+B shapes, so these throughput measurements have not been repeated for v1.2.3.**

| Maximum nodes | Cases | Node-hours | Cases/node-hour | Makespan (min) | Mean shard (s) |
|---:|---:|---:|---:|---:|---:|
| 2 | 10,240 | 1.3778 | 7432.3 | 60.6 | 496.0 |
| 4 | 10,240 | 1.3542 | 7561.8 | 25.3 | 487.5 |
| 8 (first) | 10,240 | 2.1342 | 4798.1 | 24.6 | 768.3 |
| 8 (repeat) | 20,480 | 3.4011 | 6021.6 | 31.4 | 612.2 |
| 16 | 16,384 | 2.4678 | 6639.2 | 21.2 | 555.2 |
| 32 | 32,416 | 4.8586 | 6671.9 | 27.4 | 546.6 |

Total allocated shard cost **15.5937 node-hours** (sum of rounded Slurm values); separate scheme job 7m56s. Controller estimate 15.4307 node-hours excludes some overhead. The completed directory measured about 1.2 TiB (`du -h`); sampled physical files about 6.5–7.1 MB each. Do not interpret the sum of tranche spans as end-to-end calendar time; queueing and operator gaps are omitted.

### Recommendations for future campaigns

- **Economical:** 256 workers, 1,024 cases/shard, 4 maximum nodes (v1.2.2 defaults). Best measured efficiency, ~7,562 cases/node-hour. Two nodes are nearly as economical.
- **Fast execution:** up to 32 nodes when queue and storage permit; ~6,672 cases/node-hour, 88.2% of four-node efficiency. Achieved the highest measured aggregate throughput (~71,000 cases/hour from 32,416 / 27.4 min), versus ~24,300 cases/hour for four nodes in its measured tranche. 16 is a reasonable intermediate setting. Not a guarantee of lower submission-to-completion time.
- Keep 1,024 cases/shard as the measured baseline. 2,048 or 4,096 may amortize startup/cache costs further but are **not benchmarked**; require longer walltime and fewer recovery units. Change before freezing, never repartition a frozen run. Additional total cases do not guarantee node reuse.
- Repeat benchmarks for different isotopes, source counts, event statistics and filesystem loads. These tranches are sequential observations with varying batch sizes and load, not a controlled identical-case scaling experiment.

### Long-tail effects and cache interpretation

The final array started all 32 tasks simultaneously. 30 (including the short final shard) finished in ≤542 s; shards 75 and 94 took 1613 and 1642 s. Median 477 s, mean 546.6 s. Their mean active logical CPUs were ~32–33 against ~130–190 for most full shards, with similar reported disk-read totals; this indicates more waiting or reduced CPU activity, not proof of physical Lustre saturation. No node reuse in that tranche. In the repeat eight-node run only two nodes were reused, with mixed timing results. Cache effects and shared I/O are plausible but not isolated. Slurm disk accounting does not directly measure Lustre network traffic. Do not discard outliers from actual cost or makespan.

## Earlier development benchmarks (historical, November 19 snapshot)

| Workload | Configuration | Cases validated | Runtime | Cases/node-hour | Comment |
|---|---|---:|---:|---:|---|
| Historical ¹³⁶I, same 1024 schemes | 128 workers, one node | 1024/1024 | 311.56 s | 11,832 | Older workload; direct controlled pair. |
| Historical ¹³⁶I, same 1024 schemes | **256 workers**, one node | 1024/1024 | 232.01 s | **15,889** | +34.3% throughput vs 128. Not the present full workload. |
| Full ⁹²Y+⁹²Sr, `mtas354` | 64 workers, one node | 64/64 | 99 s allocated | ~2,327 | All full-pipeline stages, intermediate cleanup. |
| Full ⁹²Y+⁹²Sr | 256 workers, one node, 4 waves | 1024/1024 | 543.59 s approximation | **~6,782** | Successful validated 1024-case benchmark. |
| Full production controller acceptance | **2 × 256 workers** on two nodes, one 256-case wave each | 512/512 | Slurm 383 s + 389 s node allocation | **~2,388** | All 512 valid; strong multi-node slowdown under investigation. |
| Controlled production comparison | 512 cases, one node, 256 workers, 2 waves | pending | pending | pending | Operator reported job started; do not infer result. |

The 512-case two-node job reached all 512 validations with no intermediate ROOT files left. Its stage means: response 188.02 s, clean 50.74 s, preprocess 36.82 s, validate 48.71 s. In the earlier 1024-case one-node run the respective means were 91.14, 8.97, 7.64, 12.51 seconds. The multi-node slowdown affects **every stage**; the likely role of shared filesystem/metadata contention is a **hypothesis, not a proven cause**. The control result is not available in this manual; the completed campaign below supplies newer production measurements.

**Note:** the first historical ¹³⁶I benchmark's node-hour throughput cannot be applied to this more complete ⁹²Y+⁹²Sr pipeline. The synthetic tests of packed workers generated enormous fake throughput figures; those are **not physics benchmarks**.

## Per-stage and resource timing

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2
export PY=/global/common/software/gen0018/mtas/root-env/bin/python3
export RUN=/absolute/path/to/project/runs/run_0001

"$PY" "$TREE/scripts/production_project.py" status --run-dir "$RUN"  # original controller for historical runs
"$PY" "$TREE/scripts/campaign_metrics.py" \
  --run-dir "$RUN" --require-complete --detailed --report-dir "$RUN/reports"
```

Per-case statuses record `wall_seconds` for `response`, `clean`, `preprocess` and `validate`, with campaign summary statistics including median, mean, 95th percentile, max. **Adding these overlapping process times is not node-hours.** `response` currently combines beta/gamma event generation, detector sorting, source-aware pileup and mixture operations; finer internal timings would require scoped instrumentation.

Use Slurm accounting for **allocated** resources:

```bash
sacct -j ARRAY_JOB_ID \
  --format=JobID%22,State%14,Elapsed,AllocCPUS,TotalCPU,MaxRSS,NodeList%20,ExitCode
```

For `n_nodes` allocated concurrently for independent shards, **node-hours** = sum over all shard task allocated seconds/3600 (one node per current shard). The total **campaign elapsed time** includes the longest wave, scheme generation, Slurm waiting, and any recovery. Slurm's `.batch MaxRSS` may aggregate memory of worker descendants and should not be mistaken for one worker's peak.

## Reference memory observations

1024 one-node run: per-process peak RSS average `926391 KiB` (~0.88 GiB); maximum `956040 KiB`. 512 two-node run: per-process average `927972 KiB`, maximum `963484 KiB`. Slurm `.batch` MaxRSS for the two shards was `174500504K` and `180314228K` (roughly 166 GiB and 172 GiB). This is comfortably below 512 GiB/node capacity, but not a guarantee for different physics or concurrent worker counts. Pileup buffers, ROOT data and per-case histogram sizes depend on configuration.

## Storage observations

| Campaign | Final physical ROOT | Final ML ROOT | Complete campaign bytes | Approx. inodes |
|---|---:|---:|---:|---:|
| 64 packed cases | 423.10 MiB | 322.12 MiB | 751.07 MiB | 1,766 |
| 1,024 packed cases | 6.58 GiB | 5.02 GiB | 11.69 GiB | 27,686 |
| 512 production two-shard cases | 3.29 GiB | 2.51 GiB | 5.84 GiB | 13,879 |
| **100,000 projection** | — | — | **~1.11 TiB** | **~2.7 million** |

These estimates follow the observed 92Y+92Sr tests and **are not upper bounds** for arbitrary isotopes or extra contaminants. The current Scratch quota reported by the operator is **20 TiB and 10 million inodes**, and existing usage is also significant. Confirm with `showquota` on launch day.

Full-scope validated cases remove `intermediate.root` (~13 MiB in early pilot) after validation; however **intermediates exist concurrently during calculation**. Peak Scratch usage depends on `max_active_nodes × workers`, active stage overlap, output compression, failed-case files, and other jobs on the filesystem. The earlier 1.11-TiB estimate does **not** cover all transient high-water marks.

## Projections and optimization decisions

If a configuration achieves actual validated throughput `R` **cases per node-hour**, estimated compute cost is

\[
\mathrm{node\ hours}_{100k}=100000/R.
\]

At `R≈7562`, this is ~13.2 node-hours; at `R≈6672`, ~15.0 node-hours (both exclude scheme generation and queueing). With `M` perfectly parallel nodes, an ideal lower-bound compute duration is `(100000/R)/M` hours, *not* a queue or deadline prediction. If the throughput degrades when more nodes share Scratch, `R` itself depends on `M`; measure rather than assume linear scaling.

Optimize only after a **controlled** comparison isolates the cost. Candidates include I/O and metadata pressure, JSON/hash verification at scale, file creation frequency, stage overlap and process packing. **Do not change pileup event definitions, accepted statistics or the physical normalization model just to improve benchmarks** without a separate scientific regression.

See [new campaign](NewCampaign.md), [checking jobs](CheckingJobs.md), [storage and archiving](StorageAndArchiving.md), [production readiness](../development/ProductionReadiness.md).
