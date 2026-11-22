# Production readiness: implementation, acceptance, remaining checks

**Status reviewed from supplied Perlmutter logs, November 19, 2026.** This table is deliberately specific: synthetic tests do not replace real physics regression; Slurm completion does not replace scientific acceptance.

| Capability | Verified evidence | Status |
|---|---|---|
| Six canonical C++ scientific applications | Source consolidation; source tarball | Implemented |
| Exact 19-crystal S+S/S+B and zero handling | Source review; pilot structural validation | Implemented; independent fixed-reference physics comparison pending |
| `physical.root` linear additive components | Pilot, 64-, 1024-, 512-case validations | Passed structural checks |
| `ml.root` shared-log components and untransformed matrix | Same cases and source review | Passed structural checks |
| Automatic intermediate deletion / restart | Step 3c pilot SKIP restart; 64/1024/512 completed outputs | Passed |
| Independent per-campaign INIs | Production controller v1.1; frozen 512-case two-shard run | Implemented and tested |
| User-selectable scope | Controller supports `schemes`, `response`, `physical`, `full` | Implemented; real partial-scope science tests still desirable |
| Deterministic, disjoint multi-node shards | 512 cases on two 256-worker nodes; 2/2 shards passed | Passed real acceptance |
| Scheme generation once, read-only SHA index | Production controller v1.1 / scheme stage | Implemented |
| Failure/resume and partial submission recovery | Synthetic tests cover retries and interrupted submission | **Real interrupted-shard acceptance still pending** |
| 1024 full cases with 256 workers on one node | 1024/1024 passed, 543.59 s allocation approximation | Passed |
| First 512-case two-node production run | 512/512 passed; ~6m23–6m29 per shard | Passed correctness; lower throughput under investigation |
| Controlled 512-case one-node comparison | User reported job started, no result yet | Pending |
| Fixed-reference nuclear-physics regression | Previously agreed, distinct from structural validation | Pending |
| Full production INI-by-INI scientific approval | To be performed with operator | Pending |
| Archival destination CFS vs other computer | Undecided | Plan/verification required before production |
| Histogram creation/saving separate switches | Not fully available in existing C++ modules | Future optimization unless shown necessary for 100k |
| Bateman chains / daughter grow-in | Explicit next scientific development request | **Not implemented; first development stage after initial production** |
| Documentation / operating manual | Modular MkDocs manual; guides and audited physics being expanded | Draft, operator review pending |

**Performance:** 64-case one-node `64 workers` ≈2327 cases/node-hour, 1024-case single-node `256 workers` ≈6782 cases/node-hour; 512 cases across two nodes at 256 workers/node ≈2388 cases/node-hour from `sacct`. These are different execution arrangements and not a controlled isolation of the cause. The 512-case single-node control test is intended to isolate launch/environment and concurrent multi-node effects. Do **not** declare the production-optimal node count or worker count until this test is analyzed. See [performance](docs/guides/PerformanceAndStorage.md).

**Next gates:** 512 control result and contention investigation; real failed-shard restart rehearsal; fixed-reference physics regression; full scientific config approval; validated archive plan; operator dry-run/launch procedure. GitHub publication can occur once production is running.

[New campaign](docs/guides/NewCampaign.md) · [100k guide](docs/guides/Production100k.md) · [recovery](docs/guides/Recovery.md) · [job status](docs/guides/CheckingJobs.md)

## Development backlog — persistent libxml2 runtime resolution (added November 20, 2026)

**Confirmed issue:** Direct execution of `bin/GenerateDecaySchemes` from an activated `root-env` shell can fail with `libxml2.so.16: cannot open shared object file`, although that library exists in `/global/common/software/gen0018/mtas/root-env/lib/`. Setting `LD_LIBRARY_PATH` temporarily resolves it. The November 20 manual generator check passed after the temporary fix (`Z=39`, `A=92`, `Qbeta=3643 keV`, 46 skeleton levels, 7 database levels). This is a runtime-library deployment issue, not a decay-scheme scientific error.

**Required permanent engineering fix (do not patch installed binaries during active production):**

1. Audit dynamic dependencies and `RUNPATH`/`RPATH` on **all** shipped C++ executables, not only `GenerateDecaySchemes`.
2. Update the canonical build/deployment configuration to encode a reliable runtime lookup path for libxml2 and other environment-specific libraries; prefer a controlled installation-time RUNPATH/RPATH or a versioned, tested launcher that resolves the shared environment. Do not rely on manual, interactive `LD_LIBRARY_PATH` exports.
3. Test from a fresh login shell and in a Slurm compute-node batch allocation, using the intended activated group ROOT environment. Confirm `ldd` shows no missing libraries and execute `GenerateDecaySchemes --check-only` against a real staged manifest.
4. Document the library/deployment contract and add a repeatable integration test in the software install/preflight procedure. Keep existing production runs pinned to their validated binaries.

**Priority:** Post-initial-tranche engineering fix; bring forward if the environment causes production jobs to fail. Distinct from Bateman grow-in (first requested *scientific* development).

**Additional deferred scientific feature:** After the 100,000-case campaign, consider preserving known γ-transition destinations while randomizing their intensities; no such feature is requested for the present frozen-science campaign.
