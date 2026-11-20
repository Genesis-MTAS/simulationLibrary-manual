# Architecture and code map

## Executable entrypoints

| Executable | Main source | Shared modules |
|---|---|---|
| GenerateDecaySchemes | `src/apps/GenerateDecaySchemes.cpp` | libxml2 internal scheme model |
| GenerateResponse | `src/apps/GenerateResponse.cpp` | sorting, mixture, pileup, background reader, ROOT I/O |
| SortResponse | `src/apps/SortResponse.cpp` | sorting, mixture, pileup |
| CleanPhysicalResponse | `src/apps/CleanPhysicalResponse.cpp` | ROOT cloning, additive validation |
| PreprocessResponse | `src/apps/PreprocessResponse.cpp` | shared-log math, decay matrix model/writer |
| GenerateDecaySchemeMatrix | `src/apps/GenerateDecaySchemeMatrix.cpp` | decay matrix model/writer, energy binning |
| campaign_driver.py | `scripts/campaign_driver.py` | staging, manifest hashes, external CLI adapter, validation |

The `Makefile` builds six independent C++ executables. The central campaign driver is optional: each program can be run separately.

## Major modules

- `src/sorting/`: experimental calibration, resolution, β gate, histograms, settings.
- `src/mixture/`: named contaminants, physical exclusive fractions, energyTime, exact-crystal pileup.
- `src/io/`: fixed-record `MTASBKG1` experimental background reader.
- `src/decay/`: exact β feeding × first-γ probability and ROOT matrix writer.
- `src/preprocessing/`: nonuniform energy binning and shared inverse-capable log transform.
- `scripts/`: input staging, campaign driver, output validation, installation checks.
- `jobs/`: Slurm pilot and individual case entry points.
- `tests/`: unit, ROOT-macro integration checks, mock campaign/restart tests.

## Validation philosophy

Preserve a clean boundary between: (a) build/unit tests, (b) structural/physical consistency, (c) numerical regression with a fixed trusted 92Y+92Sr reference, and (d) campaign-level performance/scaling. Passing a prior boundary does not imply the later ones.
