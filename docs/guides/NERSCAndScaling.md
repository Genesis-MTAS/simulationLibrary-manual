# NERSC runtime and scaling

## Known Perlmutter installation (site-specific example)

- Canonical software: `/global/common/software/gen0018/mtas/mtas-simulation`.
- ROOT: `/global/common/software/gen0018/mtas/root-env`.
- Active electron/gamma MTASBIN library: `/pscratch/sd/m/michals/MTAS/library/binary/{electrons,gammas}` (1891 + 1891 files; ~296 GiB).
- Crystal-resolved experimental background: `/pscratch/sd/m/michals/MTAS/inputs/backgrounds/background.mtasbkg`.
- Permanent master copies and reference decay XML/corrections on CFS.

Do not copy the 296-GiB response library per case. Campaign initialization stages small configs and links/copies small input files; paths must be verified for each deployment.

## Pilot job and queue priority

`sbatch` queues a job; `PD (Priority)` means it has not reached a schedulable priority and **does not indicate an MTAS executable failure**. NERSC explains that Slurm uses priority-ordered scheduling and backfill. Use:

```bash
squeue -j <jobid> -o '%.18i %.2t %.10P %.12q %.12Q %.35R'
squeue --start -j <jobid>
scontrol show job <jobid> | grep -E 'JobState=|Reason=|SubmitTime=|EligibleTime=|StartTime=|QOS=|TimeLimit='
sprio -j <jobid>
```

`--start` may show `N/A`; estimates are not guarantees. Shorter **realistic** wall-time requests can increase backfill opportunities, but do not lower time limits so much that jobs will be killed. For queue behavior see NERSC documentation: https://docs.nersc.gov/jobs/ and https://docs.nersc.gov/jobs/scheduling/ .

## Timing, memory and storage

Read per-stage elapsed wall time from `scheme_status.json`, `response_status.json`, `clean_status.json`, `preprocess_status.json`, `validate_status.json`. For peak RSS and CPU usage, collect `/usr/bin/time -v` around compute jobs or Slurm `sacct` fields. Distinguish sum of *case CPU time* from overall *campaign makespan*, which includes Slurm waiting and concurrency effects. Count both file sizes and inodes; count only stored final physical/ML outputs, not temporary files removed by the schema-2 cleanup policy.

### Scale-out progression

1 verified one-case restart/deletion pilot → 16-case limited concurrency → 64 → 1024 with final validation of every case → decide on any optimization → complete documentation and configuration signoff → start validated first 100,000-case campaign → GitHub while production runs.

Based on the first 92Y+92Sr pilot (`physical.root≈6.8MB`, `ml.root≈5.1MB`), 100,000 similarly sized cases would need ~1.19TB in final ROOT files **before** XML/logs and variability. This is an initial estimate only. The user-reported `showquota` on 2026-11-18 showed 20 TiB pscratch quota and 302.34 GiB used; these values may change. Scratch purging/backup limitations require a durable archiving plan.


> **Updated production planning:** [Full configuration reference](../reference/Configurations.md) · [Configuration worksheet](../reference/ProductionConfigurationReview.md) · [100,000-case operations](../guides/Production100k.md) · [Readiness gaps](../development/ProductionReadiness.md).


**For jobs submitted through Slurm:** see [Check NERSC job status](CheckingJobs.md) for `squeue`, `sacct`, pending reasons, array tasks and logs.
