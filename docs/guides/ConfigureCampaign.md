# Choose and review configurations for a new campaign

**Installed production workflow:** start with [New campaign](NewCampaign.md). `production_project.py create` lets you choose **copied defaults** or **copied previous-project configurations**; both give independent editable `PROJECT/config/` files. The source of configuration is only a starting point: no frozen run reads files from the defaults or a previous project.

## What to review

| INI | Main questions |
|---|---|
| `Campaign.ini` | Target input paths, 1 vs 100k cases, events/batch, scope, seed, workers, shards, nodes, QOS/time limits. |
| `GenerateDecaySchemes.ini` | Trusted nuclear levels, preserved branches, β and γ randomization, maximum energies. |
| `SortResponse.ini` | Silicon gate, IMO threshold, central correction, randomized calibration and resolution. |
| `Pileup.ini` | MTASBKG1 file, triggered/ungated secondary, S+S/S+B targets, Y cutoff, reservoir/attempt limit. |
| `Mixture.ini` | Named 0/N contaminants, `events` vs `histograms`, physical 3300 fractions, half-lives, time window and energy binning. |
| `Preprocess.ini` | Density reference width, shared-log `D0`, corrected energy axes, reconstructibility. |

### Creation and review commands

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation
export SCR=/pscratch/sd/m/michals/MTAS
export PY=/global/common/software/gen0018/mtas/root-env/bin/python3
export PROJECT="$SCR/production/MyCampaign"

"$PY" "$TREE/scripts/production_project.py" create --tree "$TREE" --project-dir "$PROJECT"
# Alternatively add --from-config /absolute/path/to/PreviousProject/config

ls -l "$PROJECT/config"
"$PY" "$TREE/scripts/production_project.py" preflight --tree "$TREE" --project-dir "$PROJECT"
```

Go through the [complete key-by-key configuration reference](../reference/Configurations.md) and [production worksheet](../reference/ProductionConfigurationReview.md) before `freeze`. Especially read [exact event-level pileup](../physics/PileupDetailed.md), [time evolution / Bateman roadmap](../physics/TimeEvolutionDetailed.md), and [physical/ML normalization](../physics/NormalizationAndReconstruction.md).

**Scope caveat:** `schemes`, `response`, `physical`, `full` are supported; sorting an already-generated EventInfo ROOT tree remains a standalone workflow. The current preflight still requests absolute `decay_xml`, `background_file`, and `central_file` paths for partial scopes. `full` deletes intermediate only after validation; `response`/`physical` retain it.

## After review

```bash
"$PY" "$TREE/scripts/production_project.py" freeze --tree "$TREE" --project-dir "$PROJECT"
export RUN="$PROJECT/runs/run_0001"
"$PY" "$TREE/scripts/production_project.py" submit --run-dir "$RUN" --dry-run
```

Submit only after reviewing the plan. For scheduling and scientific status see [Checking jobs](CheckingJobs.md); for changes after freezing, make another `run_0002`, do not edit `RUN/config`.
