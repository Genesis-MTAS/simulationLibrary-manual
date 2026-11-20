# Input files, manifest XML, and provenance

This page distinguishes the files used by the C++ programs from the files staged by the Python campaign driver.

## Decay manifest and nuclide XML

`Decay.xml` is a manifest containing `NuclideFile` entries referencing the actual parent and daughter nuclide XML files, a `StartLevel` and optionally `StopLevel`, event length and cycle length. A generated scheme normally contains:

```text
scheme_000000/
  Decay.xml
  Parent.xml
  Daughter.xml
```

`GenerateDecaySchemes` reads the input manifest and writes its own per-variation manifest, while `GenerateResponse` reads the generated manifest to sample β–γ cascades. The matrix reader uses the actual generated scheme XML to construct the β feeding × first-γ target; it does not use a detector response or a separately invented target matrix.

The staging script must preserve references between XML files. `stage_inputs.py` therefore links or copies the selected manifest **and its XML siblings**, including nested XML paths. The campaign's stored paths are not hardcoded to 92Y. The scheme generator currently supports one β− parent plus γ de-excitation; beta-delayed neutron paths are outside this generator's scope.

## External ROOT inputs

- **Central efficiency:** ROOT file containing the correction object required by `SortEngine`; configured in `SortResponse.ini` or via `--central`.
- **Event contaminants (`mode = events`):** compatible raw ROOT `EventInfo` with the 21 detector energy branches `C`, `I0..I5`, `M0..M5`, `O0..O5`, `SiTop`, `SiBottom`. Such events enter source-aware signal pileup handling after detector processing.
- **Histogram contaminants (`mode = histograms`):** precomputed ROOT `3300`, `3350`, `3351` histograms at the expected root level. These are added to the physical mixture but do **not** supply individual events for signal-pair sampling; do not conflate them with event contaminants.
- **Experimental background:** `.mtasbkg` crystal-resolved file for S+B pileup; not a ROOT TH2 substitute.
- **Particle library:** `Pure_Electron_*keV.mtasbin` and `Pure_Gamma_*keV.mtasbin` in active electron/gamma library directories.

See [binary layouts](../physics/ResponseLibraries.md) and [mixture definitions](../physics/MixturesAndPileup.md).

## Campaign-file integrity

The Step 3c driver discovers all `[contaminant:NAME]` sections generically rather than assuming a fixed contaminant list. The campaign configuration includes exact input paths and SHA-256 provenance for external files, an immutable copy of active runtime paths, and per-stage executable fingerprints. A deliberate change requires a **new campaign** or an explicit, reviewed migration; silently reusing old statuses with changed sources is unsafe.

The current deployed particle library is about 296 GB on Scratch and is **not** duplicated into every case. This is a deliberately separate reproducibility question: library directory presence is checked, but the current campaign driver is not expected to hash all 3,782 large monoenergetic files before every stage. For long-term reproducibility, record and archive a one-time library manifest/version identifier alongside campaign metadata.

## Recommended release policy

Do not include `/pscratch`, unpublished simulation datasets, the raw background, or potentially restricted nuclear data files in a public Git repository. Public documentation can explain formats and expected directory structure using placeholders. Permission to redistribute particular scientific data is distinct from permission to publish software source.
