# First 100,000-case MTAS production campaign: operator walkthrough

**Status (Nov 19, 2026): preparation guide, NOT authorization to submit production.** The new production controller is installed and its two-node **512-case acceptance campaign passed** (two 256-case shards, all cases validated and intermediates deleted). The earlier **1,024-case single-node** full-pipeline test also passed. **The 512-case single-node control test is running** to investigate the lower per-node throughput when two nodes were active. The fixed-reference physics regression and the operator's per-INI scientific review remain to be completed. Do not copy a test isotope, contaminant, random seed, or execution setting into production without review.

This walkthrough uses **the same general controller** as [Start a new campaign](NewCampaign.md). It is not a custom 100k-only tool.

## 1. Pre-launch gates

- [ ] Choose the parent/daughter target XML and verify decay scheme assumptions and response-library coverage (monoenergetic library currently ends at 10 MeV).
- [ ] Review **all six independently copied INIs**, record approved values, and select default-based or prior-project-based starting configuration.
- [ ] Confirm exact active Scratch electron/gamma library, `.mtasbkg` background, central correction ROOT and every 0/N contaminant file. Record provenance and hashes.
- [ ] Establish the fixed-reference scientific regression for the target or a representative established reference, including pileup/zeros, time evolution, physical additivity, ML inversion, and decay matrix.
- [ ] Resolve the performance control test and select `workers`, `shard_size`, `max_active_nodes`, and reasonable `shard_walltime` using measured **node-hours**, not summed per-case stage wall times.
- [ ] Demonstrate **failed-shard restart** on real Perlmutter, not only the synthetic controller tests.
- [ ] Check `showquota` **space and inodes**, plus estimated peak temporary intermediates at maximum node concurrency.
- [ ] Choose and verify an archival plan: **CFS or another machine**, still undecided. Scratch alone is not durable.
- [ ] Make sure the operator can follow this manual end to end without editing the installed C++ code or shared defaults.

## 2. Create the project (copied defaults or previous config)

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation
export SCR=/pscratch/sd/m/michals/MTAS
export PY=/global/common/software/gen0018/mtas/root-env/bin/python3
export PROJECT="$SCR/production/APPROVED_100k_PROJECT_NAME"

# Choose one route:
"$PY" "$TREE/scripts/production_project.py" create \
  --tree "$TREE" --project-dir "$PROJECT"
# OR create with --from-config /absolute/path/to/PreviousProject/config
```

The project must be a **new** directory. `create` will not overwrite an existing directory. Edit **`PROJECT/config/`**, never `TREE/config/defaults/` or a frozen `runs/run_NNNN/config/`.

## 3. Review and approve `Campaign.ini`

```ini
[campaign]
cases = 100000
events = 1000000
batch = 100000
master_seed = APPROVED_INTEGER_SEED
scope = full
stage_mode = link

[inputs]
decay_xml = /absolute/path/to/APPROVED/Decay.xml
background_file = /pscratch/sd/m/michals/MTAS/inputs/backgrounds/background.mtasbkg
central_file = /absolute/path/to/approved/central_correction.root

[execution]
account = gen0018
qos = regular
workers = 256
shard_size = 512
max_active_nodes = 2
scheme_walltime = 00:20:00
shard_walltime = 00:45:00
```

**This INI is a review template, not immediately executable:** replace the seed and every placeholder path, and **reselect** worker/node/shard/time settings after the performance investigation. `256` workers is our provisional established baseline; it is not a guarantee of best multi-node throughput. With 100,000 cases and a 512-case shard size, the run has **196** nonoverlapping shards, capped at `max_active_nodes` simultaneous allocations. Slurm scheduling delays are outside the per-node throughput measurement.

Then review, in order, `GenerateDecaySchemes.ini`, `SortResponse.ini`, `Pileup.ini`, `Mixture.ini`, and `Preprocess.ini`. See the [complete configuration reference](../reference/Configurations.md), [review worksheet](../reference/ProductionConfigurationReview.md), [pileup](../physics/PileupDetailed.md), [time evolution](../physics/TimeEvolutionDetailed.md), and [ML inverse](../physics/NormalizationAndReconstruction.md).

## 4. Preflight, freeze and audit

```bash
"$PY" "$TREE/scripts/production_project.py" preflight \
  --tree "$TREE" --project-dir "$PROJECT"
showquota

"$PY" "$TREE/scripts/production_project.py" freeze \
  --tree "$TREE" --project-dir "$PROJECT"
export RUN="$PROJECT/runs/run_0001"

"$PY" "$TREE/scripts/production_project.py" submit --run-dir "$RUN" --dry-run
```

Review the recorded shard count, job dependencies, time limits, projected output size/inodes, config hashes, source files, and approved case count. Do not submit on `preflight PASS` alone: it is a **structural validation**, not scientific approval or a guarantee of available quota.

**Freeze creates a new immutable run snapshot.** To alter configuration later, edit `PROJECT/config/`, create `run_0002`, and submit that distinct run.

## 5. Submit only after all gates pass

```bash
"$PY" "$TREE/scripts/production_project.py" submit --run-dir "$RUN"
```

The controller submits the scheme-generation stage once, then a dependent Slurm array of disjoint case shards. Each shard uses one CPU node and a bounded process pool. This is **not** one giant monolithic Slurm job and does not duplicate the response library into each campaign. The case outputs are stored in `RUN/cases/case_NNNNNN/outputs/`.

## 6. Monitor scheduling, scientific completion, and resource use

```bash
squeue -u "$USER"
"$PY" "$TREE/scripts/production_project.py" status --run-dir "$RUN"
showquota
```

For Slurm array job IDs, pending reasons, `sacct`, logs, and the distinction between Slurm success and case validation, follow **[Check job status](CheckingJobs.md)**. When the run is completely validated:

```bash
"$PY" "$TREE/scripts/campaign_metrics.py" \
  --run-dir "$RUN" --require-complete --report-dir "$RUN/reports"
```

Check Slurm *allocated* node-hours from `sacct`, plus case-stage times, node/worker memory, output ROOT sizes, inode counts, and temporary file disappearance. Note that the accepted case count and the Slurm shard array status should agree; investigate any discrepancy before calling the campaign complete.

## 7. Resume failed shards instead of starting from scratch

After a shard has exited and you've investigated its failure:

```bash
"$PY" "$TREE/scripts/production_project.py" resume \
  --run-dir "$RUN" --shards 8 --retry-failed --dry-run
```

Review and submit the actual retry command only when safe; do not rerun passed shards. See [Recovery](Recovery.md). If scheme submission succeeded but array submission did not, use `complete-submission` instead of blindly submitting another scheme job.

## 8. Storage and archival

The measured full-output data average approximately **11–12 MiB per case**, so 100,000 similar cases would create around **1.1 TiB of final ROOT files**, plus small metadata/configuration/log/XML files, with a measured extrapolation around **2.7 million inodes**. These are **estimates**, not upper bounds; the actual isotope and mixture configuration can change sizes. Scratch quota last reported: **20 TiB and 10 million inodes**; recheck `showquota` before and during production.

The production stage deletes `intermediate.root` **only once final validation passes**. At high concurrency many intermediate files coexist temporarily, so plan for **peak** usage, not just final disk usage. Preserve ROOT outputs, frozen config, per-case validations, scheme XML, fingerprints, Slurm accounting, metrics, and report manifests. Transfer to CFS **or a separately selected computer**, verifying checksums before treating the copy as an archive. See [Storage and archiving](StorageAndArchiving.md).

## 9. Completion checklist

- [ ] Exactly 100,000 requested case IDs, no unaccounted case or shard.
- [ ] All appropriate stages passed and validation evidence is preserved per case.
- [ ] Final `physical.root` + `ml.root` for every **full-scope** case, no unexpectedly retained intermediates.
- [ ] Spot-check and/or aggregate-check physical component additivity, ML round trip, matrix normalization, time-energy projection, and source fraction policy.
- [ ] Final Slurm allocation and scientific throughput report saved.
- [ ] Source and config fingerprints retained, no unexpected mutation of frozen inputs.
- [ ] Verified archive / replicated copy available before Scratch purge exposure becomes unacceptable.

**Current open issue:** the multi-node test passed scientifically but achieved markedly lower **per-node throughput** than the 1,024-case single-node test; a controlled 512-case single-node run is in progress. Do not claim optimal multi-node configuration or guarantee runtime until these measurements are reconciled.
