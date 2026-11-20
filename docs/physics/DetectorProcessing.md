# Detector calibration, resolution, gates and histograms

**Implemented in:** `src/sorting/SortEngine.cpp`, `SortConfig.cpp`, `SortResponse.cpp`; called directly by `GenerateResponse --direct-sort`.

The raw response record contains 19 MTAS crystal deposits (`C`, `I0..I5`, `M0..M5`, `O0..O5`) plus silicon `SiTop`, `SiBottom`. The β trigger uses **the maximum** of the two Si deposits, not their sum. Only β-triggered and nonzero total-MTAS events fill baseline `3300`.

## Processing order

1. Piecewise separate C and IMO calibration, with zero input preserved as exactly zero.
2. Apply once-per-response randomized (or fixed) C and IMO calibration scale changes.
3. Add missing experimental broadening based on `FWHM_exp² - FWHM_sim²`; truncate Gaussian corrections at 3σ; do not smear exact zeros into fake deposits.
4. Apply the central `TH1F Ratio` efficiency correction **after folding**, with zeroing at or below 20 keV and sampled acceptance below 300 keV.
5. Suppress IMO deposits `<=imo_threshold_keV` (default config 30 keV). Central and 18 IMO crystals then contribute to total response.
6. Fill `3300` for total energy; `3310` and `3351` retain central-zero entries whenever total is nonzero; `3305` and `3350` fill **18 individual IMO entries per accepted event, including zeros**.

The baseline raw histograms are natural event counts, not normalized distributions. Final mixture products remove unsuitable zero/low-energy bins according to the separate output-rebinning policy. Do not confuse individual IMO crystal deposits with their summed energy.

## Experimental-condition variations

`SortResponse.ini` contains `central_max_percent`/`imo_max_percent` for independent calibration and target-resolution shifts. Numeric percent `1.0` means **1%**, not a dimensionless factor 1. Separate seeds govern realized response conditions and event-level smearing. A contaminated source with `mode=events` is reprocessed with the same realized experimental conditions as the main source, but uses a separate smearing stream.

## Pitfalls

The silicon threshold is applied to raw silicon deposits; IMO threshold is applied after calibration/folding. The central correction expects an object named exactly `Ratio`. The positive-energy and zero policies differ between `3300`, `3310`, `3305`, `3350`, `3351`. See [SortResponse](../programs/SortResponse.md) and [histogram reference](../reference/OutputFormats.md).
