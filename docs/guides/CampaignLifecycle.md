# Campaign lifecycle: editable project and frozen runs

**Current implementation:** the v1.2.2 production controller supports this workflow. This is not merely a proposed design. Begin with the [hands-on new-campaign guide](NewCampaign.md); use this page for the conceptual lifecycle and data layout.

## One scientific project, many frozen runs

```text
/pscratch/sd/m/michals/MTAS/
  library/binary/{electrons,gammas}/       # one active shared response library
  inputs/                                  # shared working backgrounds/corrections
  contaminants/                            # independently prepared source data
  production/
    ProjectName/
      config/                              # six editable, independently copied INIs
        Campaign.ini
        GenerateDecaySchemes.ini
        SortResponse.ini
        Pileup.ini
        Mixture.ini
        Preprocess.ini
      runs/
        run_0001/
          config/                          # frozen run-specific configuration
          inputs/                          # staged references and provenance
          schemes/                         # individual variation XMLs
          cases/case_000000/
            config/                        # effective per-case settings
            outputs/                       # physical.root and ml.root (for full scope)
            validation.json
          jobs/                            # Slurm IDs, scheme logs, shard logs
          reports/                         # completion, times, size and inode summaries
          campaign.json
          project_run.json
        run_0002/                           # new freeze after a configuration edit
```

The active binary library is on **Scratch**, not CFS; it is **referenced**, never copied into each campaign. New software stays under `/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2`; historical runs retain their original installation. Scratch is working storage subject to quota and purge; archive data to CFS or a separately chosen external machine after verified transfer.

## Either configuration starting point is valid

- **Canonical defaults:** `production_project.py create --tree TREE --project-dir PROJECT` creates independent copies of the bundled templates. The default `Mixture.ini` starts without a contaminant; review all six files.
- **Previous approved project:** append `--from-config /absolute/PreviousProject/config` to `create`. Only the six configuration files are copied. Old ROOT outputs, case statuses and run fingerprints are not copied into the new editable project.

Neither method leaves the new editable configuration linked to its source. Once a run is frozen, the **effective immutable run configuration** is used for execution; editing the project's configuration afterward does **not** silently alter the run. For a new scientific configuration, freeze a new run rather than editing the previous one in place.

## Supported work scopes and important boundaries

`Campaign.ini` currently accepts four `scope` values:

| Scope | Current effect |
|---|---|
| `schemes` | Generate the collection of randomized decay schemes; no response array |
| `response` | Generate/sort event responses; intermediate response retained because downstream validation/cleanup is outside this scope |
| `physical` | Generate response and final physical ROOT output; ML preprocessing not requested |
| `full` | Generate response, clean physical, preprocess ML, validate, and remove the intermediate **only after validated completion** |

Existing scheme-independent **standalone** tools are available for generating a response from one explicit `Decay.xml` or for sorting an existing `EventInfo` ROOT file. The v1.2.2 controller does **not** claim an independently supported `sort_existing_events` campaign scope, nor does a `response` scope imply automatic import of arbitrary existing XML collections. See [Simulate from XML](SimulateFromXML.md) and [Sort existing events](SortExistingEvents.md).

## Actual operator sequence

1. **Create** project from defaults or a previous project: `production_project.py create`.
2. **Edit** the six standalone INIs inside `PROJECT/config/` and review them against [configuration reference](../reference/Configurations.md).
3. **Preflight**: `production_project.py preflight --tree TREE --project-dir PROJECT`. Structural PASS does **not** constitute physics approval.
4. **Freeze**: `production_project.py freeze --tree TREE --project-dir PROJECT` creates `runs/run_NNNN` and records per-run inputs/configuration fingerprints.
5. **Inspect**: `production_project.py submit --run-dir RUN --dry-run` (add explicit `--shards` for large runs) shows exact `sbatch` commands and their dependencies.
6. **Submit**: `production_project.py submit --run-dir RUN` (for at least 10,000 cases use `--shards 0-9` or another chosen initial range, except schemes-only). Schemes are generated once; a dependent bounded Slurm array runs disjoint numbered case shards, with a configurable worker pool per allocated node.
7. **Monitor** using `production_project.py status --run-dir RUN` for scientific state, and `squeue`/`sacct` for Slurm job state. See [Checking NERSC job status](CheckingJobs.md).
8. **Recover** particular failed shards with verified restart/`resume`; do not mutate successful outputs or frozen input files. See [Recovery](Recovery.md).
9. **Report and archive** `RUN/reports/` plus final ROOT products, scheme XML and metadata. Use [Storage and archiving](StorageAndArchiving.md), using the documented CFS archive and a verified destination for the full dataset.

Legacy schema-1 and schema-2 campaigns remain in their existing layouts and are **not automatically migrated**. The historical 100k production passed; every new target still requires scientific review. Fixed-reference physics regression remains separate from computational acceptance.
