# MTAS Simulation — technical and operations manual

**Draft v5, November 2026.** This manual covers the canonical six C++ scientific programs; the integrated production workflow v1.1; and the detailed source-derived definitions of event-level pileup, time evolution and physical/ML normalization. It remains a **technical draft for operator and scientific review**, not an assertion that the fixed-reference physics regression has been completed.

**Immediate order:** finalize the documentation and configuration review → launch the first validated 100,000-case production campaign yourself using the manual → publish the canonical source and documentation on GitHub while the simulation is running.

## Choose what to read

| You want to… | Start with |
|---|---|
| Create a new project from defaults or a previous project | [Create and run a campaign](guides/NewCampaign.md) |
| Understand every knob before a large run | [Configuration reference](reference/Configurations.md) and [approval worksheet](reference/ProductionConfigurationReview.md) |
| See what's pending/running/failed in Slurm | [Checking jobs](guides/CheckingJobs.md) |
| Generate decay schemes, simulate raw XML, sort existing ROOT | [Choose a task](guides/StartHere.md) |
| Understand exact S+S / S+B pileup, 3350, and zeros | [Pileup — full model](physics/PileupDetailed.md) |
| Understand independent half-lives, S+S pair decay and daughter grow-in | [Time evolution and future Bateman model](physics/TimeEvolutionDetailed.md) |
| Reconstruct a complete physical or ML spectrum from log-transformed components | [Normalization and reconstruction](physics/NormalizationAndReconstruction.md) |
| Launch the **first** 100,000-case campaign (after acceptance gates) | [100k walkthrough](guides/Production100k.md) |
| Recover a failed shard or interrupted submission | [Recovery](guides/Recovery.md) |
| Find ROOT outputs, metadata, and validation reports | [Inspect outputs](guides/InspectOutputs.md) |
| Budget space/inodes and decide on archival | [Storage and archiving](guides/StorageAndArchiving.md) |

## Scientific processing chain

```text
Source decay XML → GenerateDecaySchemes once → independent varied XMLs
                                              │
Monoenergetic electron/gamma library ──────────┤
                                              ▼
            GenerateResponse --direct-sort → processed 19-crystal events
                                              │
         detector conditions, source-aware accidental S+S/S+B, mixtures
                                              │
                            intermediate.root (temporary on full run)
                                              │
                         CleanPhysicalResponse → physical.root
                                              │
                         PreprocessResponse → ml.root + scheme matrix
                                              │
                 validate numeric invariants → delete intermediate
```

Other valid entry points include `SortResponse` on a compatible existing `EventInfo` ROOT tree, standalone `GenerateDecaySchemeMatrix`, and schemes-only or partial-scope campaigns.

### Output conventions

- `physical.root` includes only final and elementary **physically weighted, additive linear-count** histograms (`3300`, `3350`, `3351`, `energyTime`) and metadata.
- `ml.root` contains shared-log `3350`, `3351`, `energyTime` for the same elementary sources and final, plus an **untransformed** `decaySchemeMatrix` probability target and inverse-transform metadata.
- Never add transformed component channels without first applying the shared-log **inverse**. If a unit-integral distribution is needed, normalize the **reconstructed linear total** only once.
- Intermediate ROOT files are deleted after full validation by default; partial-scope outputs retain the intermediates they depend upon.

## Production evidence and outstanding checks

The user's Perlmutter logs establish a successful schema-2 cleanup/restart pilot; completed 16-case, 64-case, and **1,024-case** full-pipeline tests; and a successful **512-case two-shard, two-node** production-controller test with 256 workers per node. No failed cases or leaked intermediates were reported in the large tests. The two-node test showed substantially lower per-node throughput than the 1,024-case single-node run, so a controlled 512-case one-node comparison has been submitted and its result is pending in this manual version.

Before the 100,000-case scientific launch: resolve performance settings, test real shard failure/restart, complete fixed-reference physics regression, approve the six scientific/operational INIs, and select a verifiable archive plan. Archive destination remains **CFS or another computer**.

## Documentation basis and development

Source base: user-supplied canonical `mtas-documentation-source.tar.gz`; production-controller code: `MTAS_ProductionWorkflow_v1_1` installed and exercised on Perlmutter. This publication includes a SHA-256 source manifest so that changes between the reviewed sources and future GitHub release can be identified. Detailed implementation references cite C++ file/function names, not just intended algorithms.

The current monoenergetic electron/gamma response library ends at **10 MeV**; the **12-MeV histogram axis** is an analysis range and does not extend the available particle library.

The **first requested scientific feature in the subsequent development stage** is the Bateman parent–daughter activity model and grow-in of daughter contaminants. It is **not implemented** in this manual's source revision. See [Time evolution](physics/TimeEvolutionDetailed.md).
