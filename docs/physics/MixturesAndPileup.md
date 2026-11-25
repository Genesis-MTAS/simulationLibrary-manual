**Detailed implementation chapter:** [Read the full audited treatment](PileupDetailed.md). This page is a shorter overview.

# Contaminants, mixtures and exact-crystal pileup

**Implemented in:** `src/mixture/{MixtureConfig,MixtureRoot,PileupEngine,MixtureXml}.*`, `src/io/MTASBackgroundMappedReader.h`. `GenerateResponse --direct-sort` and `SortResponse` reuse these components.

## Composition fractions

`Mixture.ini` defines a finite set of named contaminant sources and two pileup fractions, all expressed as **exclusive shares of the final nonzero `3300` integral over [0,12000) keV**. Their sum must leave a strictly positive main share:

`f_main = 1 - sum(f_contaminant) - f_ss - f_sbkg`.

The final 3300 integral in that range is normalized to the original main 3300 integral (the established option-1 convention). Each physical source gets one scale applied consistently across `3300`, `3350`, `3351`, so its 2D-to-1D response ratios are retained. A requested 20% `3300` contaminant fraction does **not** mean that the contaminant contributes exactly 20% to every 2D bin or integral.

Fractions can be `fixed` or random uniformly selected between configured min/max; mixture draws are per case and reproducible through their recorded seeds. Invalid drawn total mixtures are retried with a 10,000-attempt cap; impossible minimum fractions error out.

## Contaminant modes

- **`events`:** file containing `EventInfo` crystal and Si branches, processed by `SortEngine` with the same realized detector conditions. Such sources can contribute primary/secondary reservoir events for mixed-source S+S/S+B pileup.
- **`histograms`:** external ROOT file providing `3300`, `3350`, `3351` at top level; contributes to final weighted shapes **after** pileup and cannot be sampled as an event-level source in pileup.
- **Zero contaminants:** valid; use an otherwise complete `Mixture.ini` without any `[contaminant:...]` sections. The Step 3c campaign driver scans arbitrary names and fingerprints all referenced external files; it never assumes Sr92 is always present.

## Pileup physics and sampling

`Pileup.ini` uses a crystal-resolved experimental background file in **MTASBKG1** fixed-record format, not the old histogram-based background. The pileup engine forms S+S and S+B pairs **after** processing individual crystal deposits. A secondary signal may be untriggered (`secondary_signal=ungated`) while the primary must satisfy the β gate. **v1.2.3:** silicon-triggered events with exactly zero MTAS total may serve as the *first* S+B member, creating background-only MTAS deposits; they are not included in the main spectrum or either S+S reservoir. The source weighting for S+B accounts for all eligible β triggers, including zero-MTAS ones. The requested S+B `3300` mixture fraction remains unchanged; only the shape can differ.

For 2D `3350`, each of the 18 IMO crystal energies is added crystal by crystal; this is not the old approximation that distributes a total noncentral energy arbitrarily among crystals. For `3351`, summed central response is used. The shared `min_2d_y_keV` applies to both 3350 and 3351 and to both pair classes; zeros still participate in the underlying energy sum. The result uses separately specified target counts for 1D/2D histograms and reports **attempt exposure and accepted-yield ratios**, rather than equating raw histogram entries with pair probabilities.

## Time distributions

`final/energyTime` has energy and time axes with a default 354 × 354 structure. The time window can be a chosen number of parent half-lives or a fixed time, with an integer-width axis in an appropriate ns/us/ms/s/min/h/day/year unit. Main and contaminants can have their own half-lives. S+S time follows pair decay rates (sum of source decay constants); S+B follows the primary source rate because the recorded background is treated as stationary. The complete time projection reproduces the physical energy spectrum, within rounding.

## Configuration

See [configuration reference](../reference/Configurations.md) for every key in `Mixture.ini` and `Pileup.ini`. The default `write_unrebinned` should be `false` for space-conscious campaigns. The cleaned final ROOT file retains only weighted elementary components; intermediate reservoirs/diagnostics are discarded after validation unless the campaign opts to keep the intermediate.
