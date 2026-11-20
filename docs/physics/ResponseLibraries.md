# Monoenergetic response library and binary formats

**Source-verified against:** `src/apps/GenerateResponse.cpp` (`MappedResponseFile`, `BetaSampler`, `Deposit`) and `src/io/MTASBackgroundMappedReader.h`. The two binary formats below have different purposes and must not be confused.

## Particle-response library

`GenerateResponse` builds one simulated β–γ cascade by drawing an individual simulated detector response for each emitted electron and γ ray, then summing the deposits in the **same 21 detector channels**. In the canonical campaign, the response library is read directly from Perlmutter Scratch, not from its archival copy on CFS:

```text
/pscratch/sd/m/michals/MTAS/library/binary/
  electrons/Pure_Electron_10keV.mtasbin ...
  gammas/Pure_Gamma_10keV.mtasbin ...
```

The actual deployed collection currently has 1,891 electron files and 1,891 gamma files and occupies about 296 GB. The current **compiled** lookup grid is 10–1000 keV in 1-keV steps, then 1010–10000 keV in 10-keV steps. The upper boundary is `constants::maxLibraryKeV = 10000` in `GenerateResponse.cpp`. The source-file comment still describes a generic grid through 12 MeV; the effective compiled limit and deployed dataset are 10 MeV. In contrast, many **output histogram** axes extend to 12 MeV; that does not add higher-energy particle files.

### `MTASBIN1` event library

Binary event files are **little-endian IEEE-754** and use fixed offsets:

| Region | Bytes | Meaning |
|---|---:|---|
| Header | 64 | `magic = MTASBIN1`, `version = 1`, `recordBytes = 84`, `nEvents`, reserved bytes |
| Event | 84 | 21 `float32` values (energy deposits, keV) |

The fields in each record are in exact sequence:

```text
C, I0..I5, M0..M5, O0..O5, SiTop, SiBottom
```

The C++ reader validates magic, version, record size, event count and file length. It uses POSIX `mmap(..., MAP_SHARED)` for read-only library access and checks the host floating-point architecture. It does not load the entire 296-GB collection into application memory at once. The reader rejects a file with zero events or a mismatched length/header. A nominal one-million-event file should be 64 + 1,000,000 × 84 = 84,000,064 bytes.

For ROOT-library mode, the corresponding `Pure_Electron_*keV.root` / `Pure_Gamma_*keV.root` files are read via ROOT. The program defaults to `--library-format root`; the Perlmutter campaigns explicitly specify `--library-format binary` and the electron/gamma directories.

### Sampling and efficiency

The β energy sampler first assigns an electron kinetic energy to an available library grid point, while each γ transition supplies a γ energy to the library lookup. The program samples an event independently from the appropriate particle-response file and adds the 21 deposits over the cascade. **A library event with no MTAS energy is still a real response outcome**: do not filter or replace zero-deposit events before composition. The library's zero/nonzero fraction contributes to the simulated detection efficiency.

In raw mode, this produces an uncalibrated event in `EventInfo`; in `--direct-sort` mode the resulting event is passed directly to the same `SortEngine` used by standalone sorting. See [GenerateResponse](../programs/GenerateResponse.md), [beta spectra](BetaSpectra.md) and [detector processing](DetectorProcessing.md).

## Experimental background: `MTASBKG1`

The experimental background used for S+B pileup is **not** an electron or gamma monoenergetic library file. It is a crystal-resolved `MTASBKG1` file. The active path during our experiments is:

```text
/pscratch/sd/m/michals/MTAS/inputs/backgrounds/background.mtasbkg
```

Its own reader requires a 64-byte header and **96-byte records**:

| Field | Representation | Meaning |
|---|---|---|
| `energy[20]` | 20 × `float32` | `Total`, `C`, and 18 individual I/M/O crystal energies |
| `timeSeconds` | `float64` | Experimental event time |
| `betaCoincident` | `uint8` | β-coincidence classification |
| reserved | 7 bytes | Padding / reserved |

It validates `magic = MTASBKG1`, version 1, record size 96, the required flags and the exact `64 + 96 × eventCount` file size. The pileup engine can filter experimentally β-coincident events with `exclude_beta_coincident`; the supplied default is `false`.

The full 19-crystal information matters: S+B deposits are combined **crystal by crystal** before total/IMO/central histograms are filled. Replacing this file with old background `TH2` spectra loses that information and changes the pileup model. See [mixtures and pileup](MixturesAndPileup.md).

## Provenance and portability

`MTASBIN1` and `MTASBKG1` are implementation-level binary layouts, not portable industry standards. Publishing the program does **not** imply redistributing the 296-GB particle library or the experimental background. The release should document how to obtain/prepare authorized library files, check record formats and configure paths on a local system. For active NERSC campaigns, only a small path reference is stored per case; the 296-GB library is not duplicated for every run.
