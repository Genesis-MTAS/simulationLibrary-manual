# Guide: prepare and configure contaminants

This guide applies to the **mixture** stage. A contaminant is not created automatically by `GenerateDecaySchemes`: it is an external source that you prepare and reference in your own `Mixture.ini`.

## Pick the input representation

| Mode | Required input | Where it participates |
|---|---|---|
| `events` | ROOT `EventInfo` tree with 21 detector-energy branches | Detector processing and source-aware signal-pair pileup |
| `histograms` | ROOT histograms `3300`, `3350`, `3351` at the expected root level | Physical mixture after pileup; cannot supply individual paired events |

An `EventInfo` file must have `C`, `I0..I5`, `M0..M5`, `O0..O5`, `SiTop`, `SiBottom`. `mode=histograms` is not equivalent to `mode=events` when S+S pileup is nonzero. Both source types must be checked for compatible energy units and appropriate experimental processing.

## Example: two named event contaminants

The following is a **fragment** to insert into a complete, source-approved `Mixture.ini`, not a complete configuration:

```ini
[contaminant:SourceA]
mode = events
file = /absolute/path/to/SourceA_events.root
intensity_mode = fixed
intensity = 0.10

[contaminant:SourceB]
mode = events
file = /absolute/path/to/SourceB_events.root
intensity_mode = fixed
intensity = 0.05
```

The source names become ROOT directory names under `components/contaminants/`. They must be unique and cannot contain `/`. Fractions like `0.10` mean 10% of the specified final nonzero `3300` count convention—not 0.10%. Review the main and pileup fractions together; the combined fractions must leave **positive main signal**. The mixture engine validates the combination rather than silently fixing impossible values.

For an empty-contaminant mixture, include the required mixture/fraction/time/binning sections **but no** `[contaminant:...]` sections. A ready example exists at `config/examples/Mixture.no_contaminants.ini` in the canonical source.

## Path provenance

The installed schema-2 driver discovers all named contaminant sections, requires unambiguous absolute external file paths, and records path, file size and SHA-256 hashes. On restart, altered source files are refused. Do not replace a ROOT contaminant file in-place once a campaign references its frozen hash; prepare a new run instead.

The driver does **not** materialize or copy every large contaminant into each case. It references the prepared file, so ensure the file is readable from all assigned compute nodes and will remain stable for the campaign.

## Time dependence

Set `main_half_life_s` and optional contaminant `half_life_s` consistently with your scientific assumptions; where supported, the engine can infer contaminant half-life from embedded source information. Configure `[energy_time]` for the desired duration and units. Verify fixed/stable or missing half-life handling before comparing energy–time templates. See [Mixture and pileup model](../physics/MixturesAndPileup.md) and [configuration reference](../reference/Configurations.md).

## A source-preparation checklist

- [ ] Input ROOT has the correct mode-specific objects, energy units and event selection.
- [ ] Named source paths are absolute and readable on compute nodes.
- [ ] All source fractions and random ranges have physically justified values.
- [ ] `mode=events` is chosen when the contaminant should enter signal-pair pileup.
- [ ] Time dependence and source half-lives are correct.
- [ ] File hashes are recorded and will not change during execution.
- [ ] Resulting physical components remain weighted and add to the final spectrum.

Run a small validated pilot for every **new** contaminant preparation method. Structural validation cannot determine whether the contaminant spectrum itself is scientifically appropriate.
