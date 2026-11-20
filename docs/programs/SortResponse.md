# SortResponse

**Source:** `src/apps/SortResponse.cpp`, `src/sorting/SortEngine.*`, `src/sorting/SortConfig.*`. Standalone sorter for existing raw ROOT `EventInfo` trees; shares its detector-processing engine with `GenerateResponse --direct-sort`.

## CLI

```bash
bin/SortResponse input_EventInfo.root output_sorted.root   [--config SortResponse.ini] [--sili keV] [--imo keV]   [--central correction.root] [--seed N] [--conditions-seed N]   [--pileup-config Pileup.ini] [--mixture-config Mixture.ini]   [--mixture-seed N]
```

CLI overrides take precedence over INI values regardless of argument order. `--seed` controls event smearing. `--conditions-seed` controls the per-response randomized detector conditions. Passing `--mixture-seed` without a mixture file is invalid.

## Input

ROOT `EventInfo` tree with `C`, six channels each for `I`, `M`, `O`, plus `SiTop` and `SiBottom`. Missing required branches are fatal. Source `EventInfo` can be produced by the raw mode of `GenerateResponse`; external event-contaminant ROOT files use the same branch model.

## Detector processing

1. **Silicon β gate** uses `max(SiTop,SiBottom) >= silicon_threshold_keV`. A secondary event retained for pileup need not satisfy the β gate when `secondary_signal=ungated`.
2. Apply piecewise calibration separately to the central crystal and each of 18 IMO crystals. Exact no-deposit zeros remain zero.
3. Apply additional Gaussian resolution broadening using the difference of squared *target experimental* and existing simulation FWHM, with a 3σ-truncated draw. Broadening cannot sharpen signals (`FWHM_target^2 <= FWHM_sim^2` gives no extra smearing).
4. Apply the central `Ratio` efficiency correction (ROOT `TH1F`) **after smearing**, including suppressing central deposits `<=20 keV`; efficiency acceptance is sampled below 300 keV.
5. Zero individual IMO deposits at or below the configured IMO threshold; sum the surviving crystals and central detector to total MTAS energy.
6. Accepted baseline events require β gate and `total MTAS > 0`. No artificial unit-count normalization is applied to the raw sorted histograms.

## Raw histograms

| Histogram | Meaning |
|---|---|
| `3300` | β-gated nonzero total MTAS, 1D |
| `3305` | Individual 18 IMO deposits per accepted event, including crystal zeros |
| `3310` | Central deposit for every accepted event, including central zeros |
| `3350` | `total MTAS` vs **each** of 18 IMO crystal energies, including zeros |
| `3351` | `total MTAS` vs central crystal energy, including zero central deposits |

Raw 1D histograms use 1-keV bins to 15 MeV and raw 2D histograms 10-keV bins to 15 MeV. The mixture final outputs use the configured energy binning (normally 354 nonuniform 0–12 MeV bins). Threshold-zero and raw histogram policies are intentionally different from the final rebinned 2D zero-Y exclusion.

## Configurations / tests

- [SortResponse.ini](../reference/Configurations.md) holds thresholds, central correction, independent C/IMO calibration and FWHM variations, and random seeds.
- Optional [Pileup.ini and Mixture.ini](../physics/MixturesAndPileup.md) add exact-crystal pileup and a final weighted source composition.
- Tests: `tests/unit/legacy/test_exact_background.cpp`, `test_multisource.cpp`, plus `tests/integration/root_macros/CompareSortedResponses.C`.

**Caution:** a direct-sort intermediate ROOT file is not the compact `physical.root` deliverable. Use `CleanPhysicalResponse` for that.
