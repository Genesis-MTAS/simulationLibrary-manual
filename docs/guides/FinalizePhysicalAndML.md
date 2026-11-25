# Guide: turn a weighted mixture intermediate into physical and ML outputs

Use this guide **only** when the input ROOT file is a mixture intermediate containing weighted `final/` and elementary `components/` histograms, not merely a raw `EventInfo` tree or standalone sorted histograms.

## Step 1: create a compact physical ROOT file

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.3
export CASE=/absolute/path/to/working/case
mkdir -p "$CASE/outputs"
"$TREE/bin/CleanPhysicalResponse" \
  "$CASE/outputs/intermediate.root" \
  "$CASE/outputs/physical.root"
```

`CleanPhysicalResponse` checks that final **linear physical counts** equal the sum of the weighted elementary components. It preserves `final/{3300,3350,3351,energyTime}` and `components/main`, optional named contaminants, `pileup_ss`, `pileup_sbkg`, plus metadata. It removes internal raw templates and redundant aggregates. It **does not** renormalize the contributions independently.

## Step 2: create the ML file and the scheme matrix

```bash
"$TREE/bin/PreprocessResponse" \
  "$CASE/outputs/physical.root" \
  "$CASE/outputs/ml.root" \
  --config /absolute/path/to/Preprocess.ini \
  --decay-xml /absolute/path/to/scheme/Decay.xml
```

The ML file contains transformed `3350`, `3351` and `energyTime` for final and components. For each family, a common reversible log transform uses **the final histogram's** density maximum and the same `D0` for all components. Independent per-component normalization is wrong. With `--decay-xml`, the *untransformed* β-feeding × first-γ matrix is inserted into `final/decaySchemeMatrix`.

## Step 3: validate before deleting any intermediate

A supported full campaign runs `scripts/validate_case.py` after both files exist; if it passes, the **schema-2 driver** deletes `intermediate.root` and records the intentional deletion. For a manual standalone chain, the cleaner/preprocessor do **not** automatically perform that final campaign cleanup. Do not delete your source ROOT file until the outputs have been checked and you have decided it is safe to discard.

Standalone validation example:

```bash
"/global/common/software/gen0018/mtas/root-env/bin/python3" \
  "$TREE/scripts/validate_case.py" \
  --physical "$CASE/outputs/physical.root" \
  --ml "$CASE/outputs/ml.root" \
  --report "$CASE/validation.json"
```

Inspect the generated JSON and confirm `passed: true` along with physical additivity, ML transform bounds, and matrix normalization. The structural check is **not** the same as a fixed-reference physics regression. See [validation and evidence](../development/ValidationAndDocumentationStatus.md).

## Retained outputs

```text
CASE/
  outputs/physical.root
  outputs/ml.root
  validation.json
```

Retain the exact `Preprocess.ini`, scheme XML, and input/implementation provenance in the surrounding project. For standalone work, you must maintain that record yourself; the schema-2 campaign driver does so automatically for its supported stages. See [output format reference](../reference/OutputFormats.md).


**For jobs submitted through Slurm:** see [Check NERSC job status](CheckingJobs.md) for `squeue`, `sacct`, pending reasons, array tasks and logs.
