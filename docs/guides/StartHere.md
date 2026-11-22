# Start here: choose the MTAS task

**For a new reproducible campaign**, the normal installed interface is [Create and run a campaign](NewCampaign.md), from either copied defaults or a prior project's copied INIs. Individual executables can still be run independently, without committing to a full campaign.

| Task | Recommended guide | Availability |
|---|---|---|
| Generate randomized scheme XMLs only | [Generate decay schemes](GenerateSchemes.md) | Standalone executable or production `scope=schemes` |
| Simulate events from an existing decay XML | [Simulate from XML](SimulateFromXML.md) | Standalone `GenerateResponse`, raw or direct-sort |
| Sort an existing `EventInfo` ROOT tree | [Sort existing events](SortExistingEvents.md) | Standalone `SortResponse`; not a `Campaign.ini` scope yet |
| Prepare input contaminants | [Contaminant inputs](Contaminants.md) | Event/histogram source files; 0/N sources |
| Make compact physical/ML outputs | [Finalize outputs](FinalizePhysicalAndML.md) | Cleaner and preprocessor, or `scope=full` |
| Generate decay-scheme matrix separately | [Matrix guide](CreateDecayMatrix.md) | Standalone program |
| Start and submit a whole or partial project | [New campaign](NewCampaign.md) | v1.2.2 maintained workflow; 100k tested on v1.2.1 |
| Work with older schema-2 benchmark directories | [Legacy campaign guide](CampaignToday.md) | Backward-compatible old run folders |
| Inspect queue, job arrays, resource usage | [Check jobs](CheckingJobs.md) | `squeue`, `sacct`, campaign status |
| Inspect results and numerical validation | [Inspect outputs](InspectOutputs.md), [Validation](ValidationWorkflow.md) | Real full-pipeline tests passed structurally |
| Restart a shard, including partial submissions | [Recovery](Recovery.md) | Synthetic recovery tests; real interrupted-shard trial pending |
| Plan storage and archival | [Storage](StorageAndArchiving.md) | CFS archive layout documented |
| Review the completed 100,000-case campaign | [100k walkthrough](Production100k.md) | Historical worked example; review settings for new runs |

## What changes between a standalone command and a campaign?

A standalone program directly reads the INI/path values supplied on its command line. A production project contains its own six independent INIs; `freeze` creates a validated immutable `runs/run_NNNN` snapshot, and Slurm executes that snapshot rather than the editable project templates. Output case locations, hashes, logs and statuses follow consistent conventions. The active response library is **shared on Scratch**, not copied per case.

For nuclear and detector details begin with [pileup](../physics/PileupDetailed.md), [time evolution](../physics/TimeEvolutionDetailed.md), and [physical/ML normalization](../physics/NormalizationAndReconstruction.md).
