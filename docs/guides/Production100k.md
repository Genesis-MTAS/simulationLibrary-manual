# Completed 100,000-case production: worked example

**Status:** all 100,000 92Y + 92Sr cases passed the v1.2.1 production controller; all 98 shards completed with exit code 0. This is a historical worked example, not an instruction to resubmit the existing run. For new campaigns use v1.2.3 and the [general guide](NewCampaign.md); do not reinterpret this v1.2.1 dataset as having the patched S+B shape.

## Approved scientific and resource setup

| Item | Historical 100k run |
|---|---|
| Run | `Production_100k_candidate_v1/runs/run_0001` |
| Scheme generation | One common skeleton: 46 levels (7 database levels); 100,000 variations |
| Parent/endpoint | 92Y, Qβ = 3643 keV; half-life 3.54 h |
| Trusted limit | 2400 keV; quasilevels up to Qβ − 200 keV |
| β shapes | Allowed fallback for unsupported shapes; use frozen model INIs |
| Detector thresholds | Silicon 75 keV, IMO 30 keV |
| Detector variations | Calibration ±1%, resolution ±5% |
| Pileup | Exact 19-crystal calculation; 1M accepted per 1D, 10M per 2D; Y ≥ 10 keV; reservoir 200k |
| Mixture | S+S 0.005–0.02; S+B 0–0.01; 92Sr 0–0.50, independent exponential activity |
| Time / energy | 5 main half-lives; 354 MTAS bins; shared-log reference density 1, width 10 keV, both 2D axes |
| Cases / composition batch / events | 100,000 / 100,000 / 1,000,000 per case |
| Packing | 256 workers, 1,024 cases/shard, 98 shards (last 672 cases) |
| Inputs | Link mode, hashed inputs including contaminant; shared Scratch library |

These are reported reviewed settings, not a replacement for the actual frozen six INIs. Do not reconstruct a historical run from this table. Inspect `RUN/config/` for authoritative values, seeds, model weights and file paths. Preserve the frozen run and original executable hashes.

## Execution record (November 2026)

The separate scheme job `61631484` completed in 7m56s. Scheme generation occurred once; subsequent `resume` submissions used disjoint ranges of the same frozen run.

| Array | Shards | Cases | Max nodes |
|---|---|---:|---:|
| 61631485 | 0–9 | 10240 | 2 |
| 61666407 | 10–19 | 10240 | 4 |
| 61683391 | 20–29 | 10240 | 8 |
| 61695179 | 30–49 | 20480 | 8 |
| 61714969 | 50–65 | 16384 | 16 |
| 61718341 | 66–97 | 32416 | 32 |

The performance and straggler analysis is in [Performance and storage](PerformanceAndStorage.md). Initial submission and later tranche commands are in [New campaign](NewCampaign.md). Changing the array throttle did not change the science or seeds.

## Read-only inspection of the historical run

```bash
mtas
OLD_TREE=/global/common/software/gen0018/mtas/mtas-simulation
TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2
RUN=/pscratch/sd/m/michals/MTAS/production/Production_100k_candidate_v1/runs/run_0001
python3 "$OLD_TREE/scripts/production_project.py" status --run-dir "$RUN"
python3 "$OLD_TREE/scripts/production_scheme_index.py" --run-dir "$RUN" --verify
python3 "$TREE/scripts/campaign_metrics.py" --run-dir "$RUN" --require-complete
```

Observed status: 98 passed, 0 failed, 0 pending. Scheme-index verification passed for 100,000 entries; index hash `264a248c8234a5192c1c76bbb206f381db697baa5559b2519baf1e99c050e59f`. The controller reports 15.4307 approximate shard node-hours, excluding startup; use Slurm accounting (15.5937 node-hours summed across the six tranches). A reproducible sample of 32 physical ROOTs passed readability, finite histogram-summary and nonempty checks; 20 histograms each. Sampled output permissions were `-rw-r----- michals:gen0018`. Full outputs had intermediates removed after validation.

This is sufficient computational acceptance for this dataset; it is not an independent fixed-reference physics validation. Further comparison to experimental spectra is scientific work.

## Reports and retention

The approximately 1.2 TiB completed run remains on Scratch. Reports are archived at CFS `MTAS/archive/production-reports/Production_100k_candidate_v1/` (`metrics/metrics.json`, `scaling/report.json`, `scaling/array_shards.csv`, `mtas_full_scaling_report.txt`). **The reports are not a backup of the full dataset.** Arrange verified durable copies of the run, inputs and library before purge; follow [Storage and archiving](StorageAndArchiving.md).

### Recreate the archived report files (while accounting is available)

```bash
REPORT=/global/cfs/cdirs/gen0018/MTAS/archive/production-reports/Production_100k_candidate_v1
# Use a new destination if the historical reports already exist; do not overwrite them.
REPORT="$REPORT/review_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$REPORT"
python3 "$TREE/scripts/campaign_metrics.py" --run-dir "$RUN" --require-complete --report-dir "$REPORT/metrics"
python3 "$TREE/scripts/production_scaling_report.py" --run-dir "$RUN" --details --report-dir "$REPORT/scaling"
```
