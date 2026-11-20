# What has and has not been validated

**Evidence as of November 19, 2026.** Keep scientific equivalence, campaign correctness, and throughput as distinct acceptance tests. This manual was reviewed against the November 18 canonical C++ source archive and the later production-controller v1.1 implementation. Changes to installed software should be checked against these references before claiming documentation applies.

## Verified in real NERSC jobs

| Test | Result | What it demonstrates |
|---|---|---|
| Canonical build/Step 3c installation | Build, local tests and manifest checks passed | Correct installation and separate runtime Scratch library |
| One-case schema-2 full pipeline | All stages passed; restart skipped; `intermediate.root` deleted | Real end-to-end correctness and intentional cleanup |
| 16-case Slurm array | 16/16 tasks reported `COMPLETED` | Multi-case independent processing, **not** efficient worker packing |
| 64-case packed one-node run | 64/64 validated; ~99 s | Independent worker pool, stage metrics and file retention |
| 1,024-case one-node 256 workers | 1,024/1,024 validated; ~543.59 s; ~6,782 cases/node-hour | High-concurrency full pipeline and storage (~11.69 GiB; ~27,686 filesystem objects) |
| 512-case, two-shard/two-node v1.1 | 512/512 validated, no intermediates; `sacct` ~0.214 node-hours | Disjoint multi-node shards, independent copied configuration, Slurm dependencies and successful completion |

The two-node 512-case test was **slower per node** (~2,388 cases/node-hour) than the earlier one-node 1,024-case run. The slowdown affected response, clean, preprocess and validation. A controlled **512-case, one-node** campaign has been submitted to distinguish resource contention from workflow overhead; its result is **not yet available** in this manual. Avoid claiming either a cause or final production throughput.

The earlier ¹³⁶I controlled benchmark used the *same* 1,024 randomized schemes and established 256 workers faster than 128 by 34.3% (15,889 vs 11,832 cases/node-hour). Its workload is not interchangeable with the current full ⁹²Y + ⁹²Sr physics pipeline.

## Scientific validations completed vs outstanding

**Passed by current per-case structural validators:** physical binwise additivity of elementary weighted components, expected final histogram existence, recorded transform metadata and ranges, decay-scheme matrix normalization, and validated intermediate cleanup/restart behavior.

**Must be completed before a production-physics acceptance claim:** independent fixed-reference ⁹²Y+⁹²Sr numerical regression; independently decoding *all* logged component cells and comparing to physical counts; review of all six campaign configurations; possible additional scientific input sanity checks if the source isotope or contaminant model changes.

The read-only [ML reconstruction script](../examples/ReconstructML.py) is a reference/checking example, not evidence that this independent comparison has already passed every bin. Its Python syntax was verified; the end-to-end uproot file operation still requires a test on the actual NERSC ROOT files.

## Final 100,000-case gate

- Approved separate `PROJECT/config/` files frozen into an unmodified run.
- Full preflight for file paths, hashes, source library, runtime resources, shards and input scope.
- Relevant independent physics regression and any requested model limitations noted.
- Measured node-hours using Slurm `sacct`, without confusing CPU-hours and allocated node-hours.
- Scratch **space and inode** headroom including temporary concurrent intermediate files; independently chosen archival destination (CFS or other machine).
- Verified monitoring, partial failure/retry and integrity-preserving restart.
- Versioned, tested operator instructions for actual production submission.

For commands, see [New campaign](../guides/NewCampaign.md), [Checking jobs](../guides/CheckingJobs.md), [Recovery](../guides/Recovery.md), and [Production readiness](ProductionReadiness.md).
