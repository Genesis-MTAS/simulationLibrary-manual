# Production configuration review worksheet

**Use this page with the actual source-controlled INIs and [complete parameter reference](Configurations.md) before starting a 100,000-case campaign.** This is a decision worksheet, **not an implicit recommendation to keep every current default**. Each item should be marked approved with its exact numerical value, a rationale, and—where it changes simulated physics—a small comparison/validation result. Version the final decision in the campaign directory (e.g. `config_review.md`/`config_review.json` with dated approval), and stage exactly those INI bytes at `init` time.

The experiment/target for the first 100,000 cases has not been selected in this documentation snapshot. Do **not** silently inherit the 92Y + 92Sr pilot as the production scientific setup.

## Configuration starting point and versioning

Choose one starting source and document it:

- [ ] **Canonical defaults** were copied to this project's editable `config/` directory (not linked).
- [ ] **Previously approved configuration** was copied from project/run: `__________` (configs only; no old status/results/metadata).

After copying, **all** settings must be reviewed, even when unchanged. Record the approved configuration bytes/hashes with the new run. The installed production controller v1.1 copies all six project INIs to an immutable run; freeze them and inspect `RUN/config/`. The separate historical schema-2 driver is retained for old campaigns. [Operator configuration guide](../guides/ConfigureCampaign.md).

## A. Scientific inputs — decide before initialization

| Decision | Present pilot / template | Action / value to approve |
|---|---|---|
| Parent, daughter, Qβ, reference decay XML and exact version | 92Y pilot only | [ ] Target: ____; XML source/date/hash: ____ |
| Physics scope | β−/γ cascades, no explicit neutron channel in current generator | [ ] Confirm model is appropriate: ____ |
| Preserved level cutoff | `trusted_energy_keV=2500` | [ ] Keep/adjust and justify: ____ |
| Skeleton upper energy and placement | `mtas_354`, from retained levels toward Qβ | [ ] Check Qβ and library range: ____ |
| Known β feeding and frozen γ pattern handling | preservation options `true` | [ ] Confirm against trusted input: ____ |
| Number of variants and generator seed | 100,000 intended | [ ] `cases=____`, seed=____ |
| β feeding models and ranges | mixed; 0.10–0.50 fed fraction | [ ] Review distribution: ____ |
| γ strength and sparsity | Eγ³exp(−Eγ/1000keV), mean 3, ≤15 branches | [ ] Review model and settings: ____ |
| Random γ-only levels | 30% chance, max 2, ≤10% cascade fraction | [ ] Review: ____ |
| Min positive β and γ branching percentages | β 0.01%, γ 1.0% | [ ] Review: ____ |

## B. Event generation, detector response and correction

| Decision | Current setting | Action / evidence |
|---|---|---|
| Events per case | 1,000,000 | [ ] Keep/adjust via campaign `--events`: ____ |
| Composition batch | 100,000 | [ ] Set based on RSS/time tests: ____ |
| Active binary library | Scratch MTASBIN1 electron/gamma files through 10 MeV | [ ] Check presence, integrity inventory, range: ____ |
| β gate threshold | 75 keV | [ ] Compare with experimental threshold: ____ |
| Individual I/M/O threshold | 30 keV | [ ] Compare with experimental selection: ____ |
| Central correction | Sr90 ratio ROOT | [ ] Approve file/version and handling: ____ |
| Calibration randomization | ±1% central and I/M/O | [ ] Keep/range/fixed: ____ |
| Resolution target randomization | ±3% central and I/M/O | [ ] Keep/range/fixed: ____ |
| Condition and smearing seeds | independent deterministic per case | [ ] Preserve stream independence: ____ |
| β shapes | generator's supported shape inference; unknown as allowed | [ ] Confirm assumptions for target: ____ |

## C. Composition and exact 19-crystal pileup

| Decision | Current pilot / canonical default | Action / evidence |
|---|---|---|
| Zero/many contaminants and modes | Pilot: Sr92 events at fixed 20% | [ ] List every named source and fraction policy: ____ |
| Contaminant source files | Absolute ROOT event/hist paths, hashed | [ ] Validate production ROOT files, embedded XML, half-lives and hashes: ____ |
| Main, S+S, S+B fractions | Pilot 78.5% / 1% / 0.5% with Sr92 20% | [ ] Define distributions and verify sum <1: ____ |
| S+S source composition and timing | source-aware pair weights | [ ] Validate overlap/time interpretation: ____ |
| Background MTASBKG1 | Scratch exact 19-crystal file | [ ] Validate file, event selection and provenance: ____ |
| Background cuts | exclude_beta_coincident=false; min_total=0 | [ ] Confirm: ____ |
| Secondary signal selection | `ungated` | [ ] Confirm: ____ |
| Pileup statistics | 1M 1D, 10M 2D accepted per family | [ ] Inspect variance and runtime before lowering: ____ |
| Reservoir and attempt cap | 200,000 and 100 | [ ] Keep/change based on tests: ____ |
| Common 2D Y threshold | 10 keV | [ ] Keep/change: ____ |

## D. Physical and ML output definitions

| Decision | Current output | Action / evidence |
|---|---|---|
| Physical energy grid | `mtas354`, 0–12 MeV | [ ] Keep/change uniformly across downstream consumers: ____ |
| Time evolution | 354 bins, 5 main half-lives, auto integer units | [ ] Set main/contaminant half-lives and range: ____ |
| Physical final and weighted components | `final`, `main`, named contaminants, `pileup_ss`, `pileup_sbkg` | [ ] Verify binwise additivity: ____ |
| High-resolution extra mixture output | `write_unrebinned=false` in pilot | [ ] **False** for production unless scientifically required. |
| Temporary ROOT between response and cleaner | schema 2 default delete after validation | [ ] **No `--keep-intermediate`**; verify actual restart. |
| ML width correction | 10 keV reference, both energy axes | [ ] Confirm density convention: ____ |
| Shared log density | `D0=1`, same family scale for components | [ ] Verify reversibility and component scale: ____ |
| Matrix | β feeding × first γ, normalized to 1, not log scaled | [ ] Validate on reference: ____ |
| Histogram creation vs saving | Not yet separately configurable across pipeline | [ ] Decide if any new switches are required before first 100k run. |

## E. Execution policy and operational limits

| Decision | Planned / measured | Action / evidence |
|---|---|---|
| Workers per CPU node | **256 provisional**, tested 136I 1024-case benchmark | [ ] Confirm current full-pipeline RSS and throughput at 256: ____ |
| Multi-node sharding | Production v1.1 validated 2 × 256-case shards on two nodes | [ ] Approve shard size and simultaneous node count after performance control test. |
| Slurm time limit | Must derive from whole-shard wall data | [ ] Record limit + safety margin: ____ |
| Restart and failed-shard policy | stage fingerprints and explicit `--retry-failed` | [ ] Rehearse interrupted job and no duplicate case writes. |
| Scratch capacity | User-reported 20 TiB / 10M inodes | [ ] Recheck before launching, including competing usage. |
| Output and metadata retention | ~1.11 TiB final ROOT; 1024/512-based ~2.7M inode projection | [ ] Measure 1024-case distribution and inode overhead. |
| Archival/replication | Scratch not permanent storage | [ ] Approve transfer/archive and purge-safe retention: ____ |
| Science gate | fixed-reference regression; all stage checks | [ ] 1024-case validation approved: ____ |
| Operating manual gate | dry-run on clean environment by user | [ ] Reproduce independent launch/monitor/restart instructions: ____ |

**Implementation note:** Production controller v1.1 has now implemented independent `PROJECT/config` inputs and hash-frozen `RUN/config` snapshots. The 512-case two-node run verified this route in real Slurm execution. Remaining science approval and fixed-reference regression are separate tasks.


## Configuration change discipline

1. Use `production_project.py create` and `freeze` to stage the **reviewed independent per-campaign INI files**; never modify the canonical shared defaults or patch frozen per-case files after initialization.
2. Use `campaign_driver.py plan --run-dir "$RUN" --audit` on the new run, and inspect an actual case INI under `cases/case_000000/config/` after case preparation.
3. Compare any scientific change with a small, independently validated reference. Keep a `config_review.md` decision record *outside* the frozen input snapshot or stage it as a recorded signed decision before production.
4. Confirm the 100,000 cases are **cases**, each with `--events` simulated decays; neither `cases` nor `events` should be inferred from another.

**Related:** [full key definitions](Configurations.md), [100k launch/readiness guide](../guides/Production100k.md), [science output](OutputFormats.md), [packed worker guide](../guides/PackedWorkers.md).


## Archive-destination decision (open)

- [ ] Destination selected: `CFS` / `other computer or storage` / `not yet selected`.
- [ ] Verified capacity (bytes and inodes), credentials/access, expected retention, transfer method and integrity checks.
- [ ] Scheduled transfer / checkpoint plan approved *before* large-scale production to avoid depending on transient Scratch retention.

The final storage choice is deliberately **not predetermined** by this manual. See [Storage and archiving](../guides/StorageAndArchiving.md).

## Planned first scientific development after 100k starts

- [ ] Implement Bateman chains, daughter grow-in and branching, as described in [Time evolution](../physics/TimeEvolutionDetailed.md). This is **not** a configuration switch in the present release.
- [ ] Define and validate how integrated source fractions map to time-dependent daughter activities and S+S/S+B accidental coincidences.
