> **Historical record:** earlier source/benchmark review and then-current open questions. For current status see [production readiness](../development/ProductionReadiness.md) and [100k results](../guides/Production100k.md).

**Compatibility note (production v1.1):** This page describes the historical schema-2 driver for existing pilots and benchmarks. For **new** projects use [Create a new campaign](NewCampaign.md); see [Job status](CheckingJobs.md). The new production controller already supports independent per-campaign INIs and sharded multi-node jobs.

# Guide: run a schema-2 campaign with the currently installed driver

This guide describes executable commands in the **November 18 Step 3c driver**. It is intended for validated pilots and scaling tests, **not** an unreviewed 100,000-case production launch. The driver's current `init` uses canonical defaults for four INIs; see [configuration limitations](ConfigureCampaign.md).

## Prerequisites

- Canonical installed tree, active Scratch particle library and compatible input XML files.
- Central correction ROOT, crystal background `.mtasbkg`, `Mixture.ini` (zero or more named contaminants) and any external contaminant files.
- New run directory **does not exist**. Parent directory exists. `init` creates the run and snapshots the inputs.
- ROOT environment Python for status/validation. Heavy response work must run in a Slurm compute allocation.

## Initialize and audit

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation
export SCR=/pscratch/sd/m/michals/MTAS
export CFS=/global/cfs/cdirs/gen0018/MTAS
export PY=/global/common/software/gen0018/mtas/root-env/bin/python3
export RUN="$SCR/production/my_pilot_schema2_v1"
export MIXTURE=/absolute/path/to/approved/Mixture.ini

"$PY" "$TREE/scripts/campaign_driver.py" init \
  --tree "$TREE" --run-dir "$RUN" \
  --decay-xml /absolute/path/to/Decay.xml \
  --background-file "$SCR/inputs/backgrounds/background.mtasbkg" \
  --central-file /absolute/path/to/central_correction.root \
  --mixture-file "$MIXTURE" \
  --commands "$TREE/config/defaults/campaign_commands.json" \
  --cases 1 --events 1000000 --batch 100000 \
  --master-seed 20261118

"$PY" "$TREE/scripts/campaign_driver.py" plan --run-dir "$RUN" --audit
```

These are **templates requiring your actual input paths**, not a production recipe that silently uses the 92Y+92Sr pilot input. No `--keep-intermediate` means delete validated intermediate ROOT files by default. `init` is not idempotent: choose a **new** run directory for a different configuration.

## Execute a pilot through Slurm

The established one-case Slurm script uses the current driver. For an existing working one-case campaign:

```bash
sbatch -A gen0018 \
  --output="$RUN/pilot-%j.out" --error="$RUN/pilot-%j.err" \
  --export=ALL,MTAS_CAMPAIGN_RUN="$RUN" \
  "$TREE/jobs/campaign_pilot_1case.slurm"
```

**Do not run the expensive full response on a login node.** Always review `plan --audit` and the source paths before submission. The Slurm wall limit and scheduling strategy should come from measured case times.

## Execute a packed single-node campaign

The installed add-on `scripts/packed_campaign.py` supports one node with 1–256 concurrent case processes. It generates/verifies the scheme collection once and executes cases independently, reusing the schema-2 driver.

```bash
"$PY" "$TREE/scripts/packed_campaign.py" \
  --run-dir "$RUN" --workers 64 --dry-run

sbatch -A gen0018 --time=00:45:00 \
  --output="$RUN/packed-%j.out" --error="$RUN/packed-%j.err" \
  --export=ALL,MTAS_CAMPAIGN_RUN="$RUN",MTAS_TREE="$TREE",MTAS_WORKERS=64 \
  "$TREE/jobs/packed_campaign.slurm"
```

The 64-worker example is a **small-scale correctness test**, not the production throughput baseline. The established controlled ¹³⁶I benchmark favored 256 workers/node; validate that on the current full workload. **Do not run two launchers on the same run simultaneously.** The packed launcher prevents this with a whole-run lock. Its existing implementation does **not** schedule disjoint shards across multiple nodes, and is not suitable for an entire 100,000-case campaign by itself.

## Status and results

```bash
"$PY" "$TREE/scripts/campaign_driver.py" status --run-dir "$RUN"
"$PY" "$TREE/scripts/campaign_driver.py" plan --run-dir "$RUN" --audit
find "$RUN/cases" -path '*/outputs/*.root' -type f | head
```

See [Inspect outputs](InspectOutputs.md), [Recovery](Recovery.md), [Packed workers](PackedWorkers.md) and [Performance and storage](PerformanceAndStorage.md).

## Partial stages

`run --until schemes|response|clean|preprocess|validate` stops at a specified stage. However, **the currently installed driver always starts its supported workflow at schemes**, and initialization still expects full-stage source files. It does not provide a general `scope=sort_only` / `scope=simulation_only` campaign yet. Use the [standalone program guides](StartHere.md) for tasks outside the current fixed campaign pipeline.
