# Create, configure, freeze, and submit a campaign

**This is the normal operator workflow for the installed production controller** `scripts/production_project.py` (v1.2.3 S+B patch, verified by a single-case real-library replay; the unchanged controller previously passed its four-case v1.2.2 integration acceptance; the completed 100k campaign used v1.2.1). It supersedes the earlier schema-2 `campaign_driver.py init` instructions for *new projects*. The schema-2 interface remains supported for older campaigns, which must not be modified or migrated in place.

## The seven-step routine

```text
create project → edit its six INIs → preflight → freeze run → dry-run submission
    → submit → monitor / validate / archive
```

The project can begin from **copied canonical defaults** or **copied configs from another approved project**. Both result in **independent, editable files** in `PROJECT/config/`. Nothing is linked to the source configs. Once frozen, the run has its own immutable snapshot; editing `PROJECT/config/` later does not change a submitted run.

## 1. Define the installed software and working location

```bash
mtas  # see Installation.md for shell initialization
export TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.3
export SCR=/pscratch/sd/m/michals/MTAS
export PY=/global/common/software/gen0018/mtas/root-env/bin/python3
export PROJECT="$SCR/production/MyCampaign"
```

Use a unique project name and an existing parent directory. Run the controller from a writable location (`cd "$HOME"`); `umask 027` is recommended. The shared **active** binary library resides under `$SCR/library/binary/{electrons,gammas}`; don't copy it into each project.

### Sharing a new project with group `gen0018`

For a **new** shared project, configure the group on the **parent directory before creating the project**. Group `gen0018` needs execute/traversal rights on higher-level path components (see [Storage and archiving](StorageAndArchiving.md)). Example with a dedicated shared parent, created once by a group member:

```bash
export SCR=/pscratch/sd/m/michals/MTAS
export TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.3
export SHARED_PARENT="$SCR/production/shared-gen0018"
umask 027
install -d -m 2750 -g gen0018 "$SHARED_PARENT"  # if not already set up
stat -c '%A %U:%G %n' "$SHARED_PARENT"
# New project path must NOT exist yet.
export PROJECT="$SHARED_PARENT/MyNewCampaign"
test ! -e "$PROJECT"
python3 "$TREE/scripts/production_project.py" create --tree "$TREE" --project-dir "$PROJECT"
stat -c '%A %U:%G %n' "$PROJECT" "$PROJECT/config" "$PROJECT/runs"
```

The setgid bit on directories propagates the `gen0018` group to new children; `umask 027` removes group write access for newly created files, but it **does not choose the group**, and `shutil.copy2` may preserve a template file's mode. Inspect the *small editable* new project before freeze; if sharing is required, correct the copied configuration file permissions before freezing. Check again after the first shard creates output files; expected ROOT outputs are `-rw-r----- user:gen0018` (and parent directories must be traversable). The original 100k campaign had this setup; the v1.2.2 four-case smoke-test instead inherited personal group `michals`. Do not change the completed 100k run to correct unrelated test-file permissions.

## 2. Create from defaults OR an established project

**A — Canonical defaults (good for a scientifically new configuration):**

```bash
"$PY" "$TREE/scripts/production_project.py" create \
  --tree "$TREE" --project-dir "$PROJECT"
```

**B — Previous project (good for a controlled modification):**

```bash
"$PY" "$TREE/scripts/production_project.py" create \
  --tree "$TREE" --project-dir "$PROJECT" \
  --from-config /absolute/path/to/PreviousProject/config
```

Choose **one**, not both. `create` refuses to overwrite a directory that already exists. The defaults route uses `config/production/Campaign.ini`, four `config/defaults/*.ini`, and a **no-contaminants** example `Mixture.ini`; decide explicitly whether that last choice is appropriate. The previous-project route copies all six independent INIs.

Your project now contains:

```text
MyCampaign/
  config/
    Campaign.ini                   # what work, which inputs, how much compute
    GenerateDecaySchemes.ini       # statistical nuclear decay schemes
    SortResponse.ini               # thresholds, calibration, resolution
    Pileup.ini                     # background and accepted pileup statistics
    Mixture.ini                    # contaminants, fractions, time and binning
    Preprocess.ini                 # energy-width correction, shared log
  runs/                            # independent frozen run snapshots
  PROJECT_NOTES.txt
```

## 3. Edit the six configuration files

Start with `Campaign.ini`:

```ini
[campaign]
cases = 1024
events = 1000000
batch = 100000
master_seed = 20261119
scope = full
stage_mode = link

[inputs]
decay_xml = /global/cfs/cdirs/gen0018/MTAS/inputs/decays/92Y/Decay.xml
background_file = /pscratch/sd/m/michals/MTAS/inputs/backgrounds/background.mtasbkg
central_file = /global/cfs/cdirs/gen0018/MTAS/inputs/corrections/Sr90_Ratio_CC12toCC1_his.root

[execution]
account = gen0018
qos = regular
workers = 256
shard_size = 1024
max_active_nodes = 4
scheme_walltime = 00:20:00
shard_walltime = 00:45:00
```

**Example:** a 1,024-case full run, using the measured production shard size. The default no-contaminant Mixture.ini must be edited if a 92Sr contribution is intended. Review every scientific input and choose a fresh seed for independent datasets. Four concurrent nodes are the economical default for multiple shards; this example contains only one shard.

`scope` currently supports:

| Scope | What it runs | What it retains |
|---|---|---|
| `schemes` | Scheme generation only | `schemes/scheme_NNNNNN/*.xml`, metadata; no response shards |
| `response` | GenerateResponse / direct-sort intermediate | `intermediate.root`; does not clean, preprocess or validate full outputs |
| `physical` | Response + CleanPhysicalResponse | `physical.root` and retained `intermediate.root` (needed for scope extension/recovery) |
| `full` | Response + clean + ML preprocessing + validator | `physical.root`, `ml.root`; `intermediate.root` removed **only after successful validation** |

The current production controller does **not** include "sort an existing ROOT EventInfo file" as a project scope: use the standalone [Sort existing events](SortExistingEvents.md) guide for that task. `preflight` currently requires the same `decay_xml`, `background_file` and `central_file` paths even for partial scopes, because staging still uses schema-2 inputs. This is an implementation constraint, not a physics requirement.

For other INIs, review [every configuration option](../reference/Configurations.md), [the approval worksheet](../reference/ProductionConfigurationReview.md), [pileup](../physics/PileupDetailed.md), [time evolution](../physics/TimeEvolutionDetailed.md), and [ML normalization](../physics/NormalizationAndReconstruction.md). The scientific INIs in `PROJECT/config/` must be **independent copies**; don't symlink them to the global defaults.

## 4. Preflight before allocating resources

```bash
"$PY" "$TREE/scripts/production_project.py" preflight \
  --tree "$TREE" --project-dir "$PROJECT"
showquota
```

Preflight checks paths, configuration structure, allowed scope, shared active Scratch library, source files, contaminant references, and shard-count limits. Its storage/inode numbers are **planning estimates**, not authoritative quotas or file-count measurements. Independently inspect the config and storage budgets for a large run; this is especially important when zero/multiple contaminants change the expected output sizes.

## 5. Freeze one immutable run

```bash
"$PY" "$TREE/scripts/production_project.py" freeze \
  --tree "$TREE" --project-dir "$PROJECT"
export RUN="$PROJECT/runs/run_0001"
```

This creates a new `runs/run_NNNN` directory and freezes the six INIs, paths, relevant SHA-256 hashes, input references, seeds, case ranges and orchestration program hashes. It does **not** edit the original project configs. Run `run_0002` is created the next time you freeze; don't overwrite `run_0001`.

```text
runs/run_0001/
  config/                       # frozen six INIs plus per-case configurations
  inputs/                       # staged approved XML, corrections, and references
  schemes/                      # generated variation XMLs
  cases/case_000000/            # case configs, output ROOT files, logs, statuses
  jobs/                         # plan, scheme index, shard reports, Slurm logs
  reports/                      # optional campaign metrics and QA
  campaign.json                 # underlying schema-2 campaign record
  project_run.json              # project snapshot, configuration hashes
  inputs_manifest.json          # provenance
```

## 6. Review submission, then submit

For fewer than 10,000 cases or a schemes-only run, the following example submits the entire requested scope. For larger response campaigns, use the explicit tranche commands below instead.

```bash
"$PY" "$TREE/scripts/production_project.py" submit \
  --run-dir "$RUN" --dry-run
```

Review the Slurm account, QOS, scheme generation job, shard count, `--array` and `%max_active_nodes`, time limits and selected worker count. If correct:

```bash
"$PY" "$TREE/scripts/production_project.py" submit --run-dir "$RUN"
```

Scheme generation runs **once**; every shard starts after it has succeeded. The current shard launcher requests all 256 logical CPUs per node even if `workers` is smaller; a four-worker smoke test is not a four-CPU resource allocation. One array task maps to a **fixed disjoint case range** and runs up to `workers` independent processes on one CPU node; passed cases are verified and skipped on restart. A large campaign is one project/run from your perspective, even if Slurm schedules hundreds of array tasks.

### Large campaigns: explicit initial selection and subsequent tranches

For 10,000 or more cases (except `schemes` scope), the controller requires explicit `--shards` on initial submission. With 100,000 cases and 1,024 cases/shard there are 98 tasks, IDs 0–97; the last has 672 cases. Example:

```bash
"$PY" "$TREE/scripts/production_project.py" submit --run-dir "$RUN" --shards 0-9 --dry-run
"$PY" "$TREE/scripts/production_project.py" submit --run-dir "$RUN" --shards 0-9
```

Wait for the scheme stage and current array to finish; verify passed shard IDs and Slurm exit codes. Then:

```bash
"$PY" "$TREE/scripts/production_project.py" resume --run-dir "$RUN" --shards 10-19 --dry-run
"$PY" "$TREE/scripts/production_project.py" resume --run-dir "$RUN" --shards 10-19
```

Choose unsubmitted ranges until all are passed. To retry previously submitted failed tasks, diagnose first and add `--retry-failed`; the controller rejects active or passed tasks. See [Recovery](Recovery.md). The conservative guard requires prior arrays to be inactive, with complete accounting available. Do not submit overlapping tranches. An initial small submission may omit `--shards`; scheme-only mode must omit it.

To change concurrency without changing the frozen scientific configuration, use the array ID printed by the controller (or inspect `RUN/jobs/submissions.jsonl`):

```bash
ARRAY=12345678  # replace with the actual new array ID
scontrol update JobId="$ARRAY" ArrayTaskThrottle=32
scontrol show job "$ARRAY" | grep -E 'ArrayTaskId|ArrayTaskThrottle|JobState'
```

This scheduling override does not change case IDs, seeds or shard size. Record the actual throttle and start/end overlap; it is not a guarantee of instantaneous node allocation. The next tranche again uses the frozen default until overridden. Do not edit the frozen INI to change concurrency. Select 4 for economy or test up to 32 for elapsed-time priority; see [measurements](PerformanceAndStorage.md).

## 7. Monitor, inspect, and recover

```bash
squeue -u "$USER"
"$PY" "$TREE/scripts/production_project.py" status --run-dir "$RUN"
"$PY" "$TREE/scripts/campaign_metrics.py" \
  --run-dir "$RUN" --require-complete --report-dir "$RUN/reports"
```

Use `campaign_metrics.py --require-complete` **after** all stages have passed; while running, the normal `status` command is more appropriate. For Slurm job IDs, array states, pending reasons, logs, and the difference between `COMPLETED` and scientifically validated, see [Check NERSC job status](CheckingJobs.md). For errors and reruns use [Recovery](Recovery.md). For output contents see [Inspect outputs](InspectOutputs.md), and for archiving see [Storage](StorageAndArchiving.md).

## Operator principles

- **Never edit a frozen run's INIs, XMLs, case outputs, or metadata.** To change science or resources in a way not supported by an explicit runtime override, edit `PROJECT/config/` and freeze a new run.
- The software defaults are **references**, not live-linked configuration. A previous project's config is an equally valid starting source.
- Keep intermediate ROOT only when the chosen scope needs it; for a validated full run automatic deletion is essential at 100,000 cases.
- Do not launch several hand-built `packed_campaign.py` instances against one run. Use the tested production sharding controller.
- Archive reports and approved historical bundles under CFS `MTAS/archive/`; arrange a verified durable copy of valuable datasets and inputs before Scratch purge. See [storage and archiving](StorageAndArchiving.md).
