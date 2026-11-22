# Production readiness and remaining development

Review snapshot November 22, 2026. The 100k campaign used v1.2.1; v1.2.2 is non-physics maintenance. No scientific C++ algorithms were modified.

| Capability | Evidence / status |
|---|---|
| Full production orchestration | 98/98 shards and 100,000 cases passed; no failures recorded |
| Scheme index | 100,000 indexed schemes passed SHA-256 verification |
| File integrity sampling | 32/32 physical ROOTs readable, 20 histograms each, finite summaries and positive content |
| Historical permissions | Sampled outputs 0640, gen0018; setgid and batch umask tested |
| Maintenance source audit | 99 canonical files verified, 11 replacements / 4 added |
| NERSC build/link | All six binaries built; runtime checks without LD_LIBRARY_PATH passed |
| NERSC regression | 30 Python tests and preserved C++ modular tests passed |
| Live v1.2.2 acceptance | Four-case real-library run submitted; final result pending (array 61769631) |
| Fixed-reference scientific regression | Still distinct; not demonstrated by production validation |
| Real interrupted-shard recovery | Synthetic retry/recovery tests passed; real deliberate interruption not documented |
| Durable data backup | Historical software/tests/reports archived; full 100k dataset backup not confirmed |

## Implemented maintenance

- `production_scheme_index.py`: ctime retained in descriptor but ignored for fast identity matching; full verification still hashes SQLite and status files; per-case XML SHA verification unchanged. Historical compatibility is restricted to audited hashes.
- v1.2.1 Slurm completion/resume guard retained; explicit initial tranches and conservative no-overlap recovery. `campaign_metrics.py` defaults to shard-only summary; `--detailed` scans cases, `--detailed --scan-storage` traverses storage. New `production_scaling_report.py` collects Slurm accounting while records exist.
- Both production launchers set `umask 027`. Setgid and group ownership remain administrative setup.
- `GenerateDecaySchemes` RUNPATH now resolves libxml2 through the ROOT environment. Build in writable Scratch, deploy on login nodes. Defaults 256 workers / 1024 cases per shard / 4 nodes. Source manifest corrected for active Scratch runtime paths.

## Deferred development (not part of maintenance)

- Bateman parent–daughter ingrowth and coupled activities; first planned scientific feature. Independent contaminants are not daughter growth.
- Optional variation of known gamma intensities while retaining known destinations; currently trusted connections and intensities are frozen by the chosen preservation policy.
- Fine-grained histogram creation vs saving controls and independent performance tuning. Do not change event statistics, zero handling, normalization or physics for speed.
- Investigate stragglers and I/O, larger shards, node-local reuse or higher concurrency using separate controlled tests; none is a prerequisite to accepting the completed campaign.
- Scientific comparisons to fixed references and experiment, plus archive/preservation of full campaign and response library. Confirm four-case maintained-release acceptance before declaring live v1.2.2 production verified.

See [worked campaign](../guides/Production100k.md), [performance](../guides/PerformanceAndStorage.md), [Installation](../guides/Installation.md), and [storage](../guides/StorageAndArchiving.md). The earlier readiness snapshot is retained at repository root for history.
