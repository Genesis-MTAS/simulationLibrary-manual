# Guide: sort an existing ROOT `EventInfo` tree

`SortResponse` is for cases where event-level deposited energies were generated earlier or supplied in a compatible ROOT file. It shares the detector-processing engine with `GenerateResponse --direct-sort`.

## Required input

The ROOT input must contain a tree named `EventInfo` with **float-compatible** branches `C`, `I0`–`I5`, `M0`–`M5`, `O0`–`O5`, `SiTop`, and `SiBottom`. The sorter rejects missing branches and an empty tree. The geometry is 1 central plus 18 surrounding NaI crystals and two silicon energy sums.

An existing file with histograms **only** is not an `EventInfo` input and cannot be passed to `SortResponse`.

## Prepare a project-specific configuration

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation
export PROJECT=/pscratch/sd/m/michals/MTAS/production/sort_existing_example
mkdir -p "$PROJECT/config" "$PROJECT/outputs"
cp "$TREE/config/defaults/SortResponse.ini" "$PROJECT/config/"
```

Review `[sorting]`, `[calibration]`, `[resolution]` and `[random]` settings. By default the beta gate uses `max(SiTop,SiBottom) >= 75 keV`, and the I/M/O threshold is 30 keV; these are *template values*, not universally valid experimental choices. Central efficiency correction is applied **after** resolution folding. Calibration and target-FWHM variations can be fixed or randomly sampled once per response.

## Sort raw events

```bash
"$TREE/bin/SortResponse" /absolute/path/to/input_EventInfo.root \
  "$PROJECT/outputs/sorted.root" \
  --config "$PROJECT/config/SortResponse.ini" \
  --central /absolute/path/to/central_correction.root \
  --seed 12345 --conditions-seed 54321
```

The command-line overrides apply even if the configuration contains different seeds or paths. Do not reuse the input file as the output path.

## Optional full mixture

To compose a final spectrum with source-aware pileup and contaminants, provide the additional project-specific `Pileup.ini` and `Mixture.ini`:

```text
--pileup-config /absolute/path/to/Pileup.ini
--mixture-config /absolute/path/to/Mixture.ini
--mixture-seed 123456
```

This requires scientifically appropriate background and contaminant sources. The mixture output is an **intermediate** file; use [Finalize physical and ML](FinalizePhysicalAndML.md) for the compact final products.

## Inspecting the sorter output

Raw sorted names include `3300` (total MTAS), `3305` (I/M/O crystal entries), `3310` (central), `3350` (total versus each I/M/O), and `3351` (total versus central). The fully rebinned mixture uses the selected physical energy binning and includes `energyTime`.

The legacy raw `3350` can include a crystal-energy zero for an accepted event; the final rebinned spectrum/pileup Y threshold policy is different. Do not reinterpret raw and final histograms as if they have identical zero-handling rules. See [SortResponse](../programs/SortResponse.md), [Detector processing](../physics/DetectorProcessing.md), and [histograms](../reference/OutputFormats.md).


**For jobs submitted through Slurm:** see [Check NERSC job status](CheckingJobs.md) for `squeue`, `sacct`, pending reasons, array tasks and logs.
