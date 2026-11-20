# GenerateResponse

**Source:** `src/apps/GenerateResponse.cpp` plus `src/sorting/`, `src/mixture/` and `src/io/`. This program samples complete decay cascades and combines electron/gamma MTAS library events. The **direct-sort** mode is the default for campaigns and avoids writing a raw `EventInfo` tree.

## CLI

```bash
bin/GenerateResponse Decay.xml LIBRARY_DIR response.root [options]
```

| Option | Function / defaults |
|---|---|
| `--events N`, `--batch N` | Complete decays and in-memory batch size; both default 1,000,000 |
| `--library-format root|binary` | Default `root`; campaigns use `binary` |
| `--electron-dir PATH`, `--gamma-dir PATH` | Override separate particle library directories; otherwise positional library path |
| `--seed N` | Base event RNG seed; default 12345 |
| `--level-tol X` | Nuclide target-level matching tolerance; default 1.0 keV |
| `--all-allowed` | Use allowed spectrum unless a β shape is explicitly encoded in XML |
| `--validate-only` | Parse scheme and construct β tables; no event sampling or library reads |
| `--direct-sort` | Process composed events through shared `SortEngine` rather than save `EventInfo` |
| `--sort-config PATH` | `SortResponse.ini` for direct sorting |
| `--pileup-config PATH` | `Pileup.ini` for direct sorting |
| `--mixture-config PATH`, `--mixture-seed N` | Named contaminants, pileup fractions, final 354-bin composition; optional per-case draw seed |
| `--sort-seed N`, `--conditions-seed N` | Separate sorting/smearing and randomized-condition streams |
| `--sili X`, `--imo X`, `--central PATH` | Override detector thresholds and central-efficiency correction |

The last eight sorting/mixture options require `--direct-sort`. `--mixture-seed` requires `--mixture-config`. Non-direct raw mode rejects more than `2^24` generated events because its `EventID` is `Float_t`; direct-sort avoids that limitation (but still follows runtime/memory and library limits).

## Sampling procedure

The XML loader resolves the `Decay.xml` manifest and referenced nuclide files, target levels within `--level-tol`, transition intensities and optional stop level. `StopLevel` is optional; a level with no outgoing transitions is terminal. A single cascade has a 100-transition safety limit. `type="Fake"` transitions are ignored. Only supported γ and β− transitions are simulated.

For each β branch, `BetaSampler` builds a discrete electron-energy sampler from endpoint `Qβ−E(level)`, the relativistic Coulomb/Fermi factor, and an optional shape factor. It integrates the resulting spectrum using midpoint quadrature and assigns probability to the nearest available monoenergetic electron library energy. A sampled γ selects its energy from the recorded transition energy. For each particle, the generator samples a response event from the library and sums the 19 MTAS crystals and two silicon detector deposits across the cascade, preserving exact zero deposits.

**β-shape handling:** explicit `BetaTransitionType` overrides inferred spin/parity classification. Unknown shapes, missing quantum numbers and higher-order cases intentionally fall back to the allowed approximation. The implementation contains shape factors for codes 0–4. Screening is explicitly disabled in the code metadata. See [BetaSpectra](../physics/BetaSpectra.md).

## Library and event data

- ROOT monoenergetic files or binary `.mtasbin` (binary reader uses memory mapping).
- Fixed energy grid: 1-keV increments from 10 to 1000 keV and 10-keV increments thereafter.
- **Current source constant:** `maxLibraryKeV = 10000` (not 12000) at `GenerateResponse.cpp:76`. The deployed monoenergetic library currently ends at 10 MeV, consistent with this setting. Extending it would require additional library files and a code rebuild.
- `EventInfo` includes crystal channels `C`, `I0..I5`, `M0..M5`, `O0..O5`, `SiTop` and `SiBottom` (plus event information when raw output is selected).

## Direct-sort execution

```bash
bin/GenerateResponse /scratch/scheme_000000/Decay.xml   /scratch/library/binary case_intermediate.root   --library-format binary   --electron-dir /scratch/library/binary/electrons   --gamma-dir /scratch/library/binary/gammas   --events 1000000 --batch 100000 --seed 12345   --direct-sort --sort-config SortResponse.ini   --pileup-config Pileup.ini --mixture-config Mixture.ini   --central /path/to/correction.root
```

The same `SortEngine` is shared with `SortResponse`; direct sorting also supplies mixture composition and pileup if requested. Detector calibration/resolution, correction, beta gate, crystal thresholds, raw histograms, sources, mixture weights and 2D time evolution are handled by shared modules. See [Detector processing](../physics/DetectorProcessing.md) and [Mixtures and pileup](../physics/MixturesAndPileup.md).

## Outputs and provenance

- Raw mode: an `EventInfo` ROOT tree containing event-level information, suitable for later `SortResponse`.
- Direct sort without mixture: sorted histograms and detector/pileup metadata.
- Direct sort with mixture: richer **intermediate** ROOT file with raw source templates, final weighted physical components, normalized fractional composition, time evolution and metadata; `CleanPhysicalResponse` later creates the compact deliverable.
- Error conditions include missing target level, invalid endpoint, absent library energy, bad format/header, missing correction or rejected mixture constraints.

This generator is the likely main performance hotspot, but exact relative cost is to be **measured** during scaling trials, not assumed.

## Detailed software and model boundaries

The program runs the cascade-level physics and library-event composition. The `--direct-sort` option does not merely omit the `EventInfo` branch: it passes the composed detector deposits through shared `SortEngine`, with optional mixture and pileup processing, then writes histograms directly. This reduces raw-event storage while retaining the same sorting model used by `SortResponse`.

In binary mode each requested monoenergetic response opens a memory-mapped `MTASBIN1` file, checks its 64-byte header and 84-byte record layout, selects a random event and adds the crystal and silicon deposits to the composite. Because raw deposited energies are summed before sorting, detector calibration, resolution folding, the central acceptance correction and the beta trigger are applied to the composite rather than to each individual particle. No-deposit outcomes remain legitimate event samples. See [library formats](../physics/ResponseLibraries.md).

The `--all-allowed` option is not a claim that all nuclear transitions are allowed; it forces the fallback shape selection unless an explicit supported `BetaTransitionType` is present. The source uses a relativistic Fermi correction and optional shape factors but no atomic screening. Its current library-lookup range ends at 10 MeV, consistent with the installed monoenergetic files. A 12-MeV *histogram* axis does not extend this particle input range.

The output root type depends on the mode and configuration. A campaign with a mixture produces an **intermediate** physical ROOT file because cleanup still needs to discard raw/internal objects. The canonical retained products are produced by [CleanPhysicalResponse](CleanPhysicalResponse.md) and [PreprocessResponse](PreprocessResponse.md).

### Direct-sort minimal command pattern

```bash
bin/GenerateResponse schemes/scheme_000000/Decay.xml \
  /pscratch/sd/m/USER/MTAS/library/binary intermediate.root \
  --library-format binary \
  --electron-dir /pscratch/sd/m/USER/MTAS/library/binary/electrons \
  --gamma-dir /pscratch/sd/m/USER/MTAS/library/binary/gammas \
  --events 1000000 --batch 100000 --seed 12345 \
  --direct-sort --sort-config SortResponse.ini \
  --pileup-config Pileup.ini --mixture-config Mixture.ini \
  --central /absolute/path/to/central_correction.root
```

Use the same precise experimental settings as the reference campaign when comparing outputs; random detector-condition streams and mixture draws have their own seeds. Do not infer performance from these flags: measure the response stage, including sorting and pileup, before allocating large campaigns.
