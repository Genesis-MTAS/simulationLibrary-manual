# Guide: simulate MTAS response from an existing decay scheme

Use `GenerateResponse` if you have a valid `Decay.xml` (and its referenced nuclide XML) and want raw detector events or a directly sorted response. You do **not** have to generate random decay schemes first.

## Choose a mode

| Mode | How to invoke | Output | Appropriate next operation |
|---|---|---|---|
| Raw detector events | No `--direct-sort` | ROOT `EventInfo` tree | [Sort existing events](SortExistingEvents.md) |
| Direct sorting only | Add `--direct-sort --sort-config ...` | Sorted ROOT histograms | Inspect sorted detector response |
| Full physical mixture | Also add `--mixture-config ...` and appropriate pileup inputs | Rich sorted mixture intermediate | [Clean + ML](FinalizePhysicalAndML.md) |

The three modes are **not interchangeable**. Do not feed an arbitrary raw tree or plain sorted ROOT file to `CleanPhysicalResponse`; that tool expects the weighted component/final directory structure produced by the mixture pipeline.

## Shared inputs

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation
export LIB=/pscratch/sd/m/michals/MTAS/library/binary
export SCHEME=/absolute/path/to/scheme_000000/Decay.xml
export OUT=/pscratch/sd/m/michals/MTAS/production/standalone_response_example
mkdir -p "$OUT"
```

Choose a scheme whose emitted electron/gamma energies fall within the library lookup range (currently up to 10 MeV), and verify the required `.mtasbin` files are present. The source samples **1,000,000 full decays** by default; set `--events` and `--batch` explicitly for repeatability.

## A. Produce a raw `EventInfo` tree

```bash
"$TREE/bin/GenerateResponse" "$SCHEME" "$LIB" "$OUT/raw_events.root" \
  --library-format binary \
  --electron-dir "$LIB/electrons" --gamma-dir "$LIB/gammas" \
  --events 1000000 --batch 100000 --seed 12345
```

This produces unprocessed per-crystal deposits. No detector threshold/central efficiency correction is applied in this raw-event output. Sort later using your chosen experimental settings.

## B. Produce a directly sorted response

```bash
"$TREE/bin/GenerateResponse" "$SCHEME" "$LIB" "$OUT/sorted.root" \
  --library-format binary \
  --electron-dir "$LIB/electrons" --gamma-dir "$LIB/gammas" \
  --events 1000000 --batch 100000 --seed 12345 \
  --direct-sort --sort-config "$OUT/config/SortResponse.ini" \
  --sort-seed 22345 --conditions-seed 32345 \
  --central /absolute/path/to/central_correction.root
```

Before running, create the project-specific config by copying the canonical default or an approved earlier copy and editing **your project's** file. The `--central` path overrides the INI. The direct-sort output is not necessarily a complete physical mixture.

## C. Full mixture + exact pileup

Add to the above direct-sort invocation:

```text
--pileup-config /absolute/path/to/Pileup.ini
--mixture-config /absolute/path/to/Mixture.ini
--mixture-seed 42345
```

The mixture INI identifies the main/contaminant fractions, time evolution and output energy grid. Nonzero S+S/S+B fractions require the pileup config, which points to a valid `MTASBKG1` file for S+B. Event contaminants supply an `EventInfo` tree; histogram contaminants enter differently and cannot be used as event-pair pileup sources. The result is an intermediate, **not** the deliverable physical ROOT file.

Then follow [Finalize physical and ML](FinalizePhysicalAndML.md). Check the configuration of **both** detector conditions and stochastic fractions; the main seed does not control every independent random stream.

## Validation-only run

```bash
"$TREE/bin/GenerateResponse" "$SCHEME" "$LIB" - \
  --validate-only --library-format binary
```

This checks the scheme and builds beta tables without reading the response library or composing events. It is useful as a first check, but does **not** certify output histograms or scientific validity. See [GenerateResponse](../programs/GenerateResponse.md) and [beta physics](../physics/BetaSpectra.md).


**For jobs submitted through Slurm:** see [Check NERSC job status](CheckingJobs.md) for `squeue`, `sacct`, pending reasons, array tasks and logs.
