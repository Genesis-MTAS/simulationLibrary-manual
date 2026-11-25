# MTAS Simulation — technical and operations manual

**Review draft v6.3 — November 25, 2026.** Adds source-verified detailed β-feeding and γ-transition model chapters for `GenerateDecaySchemes`; the v1.2.3 S+B zero-trigger patch and its passed single-case regression remain documented from v6.2. Installation of the separate v1.2.3 production tree was confirmed by the user, including six executable checksum checks. New full-controller acceptance is deferred. Historical 100k v1.2.1 results and four-case v1.2.2 acceptance remain unchanged; independent fixed-reference scientific validation is a separate task.

## Choose what to read

| You want to… | Start with |
|---|---|
| Create a new project from defaults or a previous project | [Create and run a campaign](guides/NewCampaign.md) |
| Understand every knob before a large run | [Configuration reference](reference/Configurations.md) and [approval worksheet](reference/ProductionConfigurationReview.md) |
| See what's pending/running/failed in Slurm | [Checking jobs](guides/CheckingJobs.md) |
| Generate decay schemes, simulate raw XML, sort existing ROOT | [Choose a task](guides/StartHere.md) |
| Understand the statistical β and γ decay-scheme generation models | [β-feeding models](physics/BetaFeedingModels.md), [γ-transition models](physics/GammaTransitionModels.md) and [cascade validation](physics/DecaySchemeValidation.md) |
| Understand exact S+S / S+B pileup, 3350, and zeros | [Pileup — full model](physics/PileupDetailed.md) |
| Understand independent half-lives, S+S pair decay and daughter grow-in | [Time evolution and future Bateman model](physics/TimeEvolutionDetailed.md) |
| Reconstruct a complete physical or ML spectrum from log-transformed components | [Normalization and reconstruction](physics/NormalizationAndReconstruction.md) |
| Review the completed 100,000-case campaign | [100k walkthrough](guides/Production100k.md) |
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

All 100,000 cases and 98 shards passed; scheme index and 32 sampled ROOT outputs passed. See [completed campaign](guides/Production100k.md) and [scaling recommendations](guides/PerformanceAndStorage.md). The full dataset remains on Scratch; archive before purge. v1.2.2 source, NERSC build and regression tests, and real-library four-case acceptance passed. The four-case smoke test is not a comparable production throughput benchmark; see [Installation](guides/Installation.md).

## Documentation basis and development

Source basis: v5.1 physics review, v1.2.2 maintenance source archive, and the v1.2.3 two-file S+B patch with SHA-256 manifest and passed single-case replay reported November 24. SOURCE_MANIFEST.csv and RELEASE_SOURCE_MANIFEST.csv remain historical snapshots of their source versions; `SB_ZERO_TRIGGER_SOURCE_HASHES.json` records the two v1.2.3 source replacements. Detailed implementation references cite actual C++ functions.

The current monoenergetic electron/gamma response library ends at **10 MeV**; the **12-MeV histogram axis** is an analysis range and does not extend the available particle library.

The **first requested scientific feature in the subsequent development stage** is the Bateman parent–daughter activity model and grow-in of daughter contaminants. It is **not implemented** in this manual's source revision. See [Time evolution](physics/TimeEvolutionDetailed.md).

## v1.2.3 S+B patch status (November 24, 2026)

The v1.2.3 patch passes a one-case comparison against the completed 100k production run: ordinary main, S+S and 92Sr contaminant components are bin-identical; S+B shape is different; the S+B final `3300` fraction remains 0.753500%. β-triggered zero-MTAS events are included as virtual S+B primaries only. The user confirmed successful installation into a separate Global Common v1.2.3 tree, including checksums for all six compiled executables; a new end-to-end full-controller campaign remains deferred. See [installation](guides/Installation.md) and [exact pileup physics](physics/PileupDetailed.md).
