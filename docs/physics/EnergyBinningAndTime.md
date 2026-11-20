**Detailed implementation chapter:** [Read the full audited treatment](TimeEvolutionDetailed.md). This page is a shorter overview.

# Energy binning, time evolution, and physical dimensions

**Implementation:** `src/preprocessing/EnergyBinning.cpp`, `src/mixture/MixtureConfig.cpp`, `src/mixture/MixtureRoot.cpp`. The energy-axis convention for the final mixture is distinct from the range of the monoenergetic particle-response library.

## Energy-bin profiles

The standard output profile is `mtas354`: 354 nonuniform energy bins spanning **0–12,000 keV**. Its bin widths are:

| Energy interval (keV) | Bin width (keV) |
|---|---:|
| 0–40 | 40 |
| 40–1500 | 10 |
| 1500–2500 | 20 |
| 2500–3400 | 30 |
| 3400–4400 | 40 |
| 4400–5500 | 50 |
| 5500–6520 | 60 |
| 6520–7500 | 70 |
| 7500–8540 | 80 |
| 8540–9800 | 90 |
| 9800–12000 | 100 |

The explicit profile is constructed in `MTAS354Edges()`. In contrast, `GenerateDecaySchemes` labels its skeleton option `binning_profile = mtas_354` (underscore); the mixture uses `energy_binning.model = mtas354` (no underscore). Do not copy one spelling into the other program.

The mixture also supports `uniform` bins and custom edge files. Energy edges must start at 0, end at 12,000 keV, be strictly increasing and lie on the 10-keV grid of raw 2D spectra. Uniform widths must divide 12,000 keV exactly and be at least 10 keV. The implementation allows at most 1,200 energy bins. Custom edge files are resolved relative to their `Mixture.ini` location when given a relative path.

The output 12-MeV **analysis axis** and the current 10-MeV **monoenergetic response-library limit** are not contradictory. Particle energies above the library limit cannot be assumed to be simulated just because the histogram has bins up to 12 MeV.

## Time-axis construction

When `[energy_time] enabled = true`, the default total observation window covers `half_lives × main_half_life_s`, with five half-lives in the historical 92Y+92Sr example. `time_range_mode = fixed` uses `max_time_s` instead. Time bins are chosen to give 354 integer-width bins in one of `ns`, `us`, `ms`, `s`, `min`, `h`, `day`, or `year` (`auto` chooses the most suitable); a fixed positive `time_bin_width` may override the automatic integer width.

Time intervals are treated as fractions of a **finite normalized observation window**. If the decay constant is `λ = ln(2) / T_1/2`, the fraction of decays in `[a,b]` conditional on observation during `[0,T]` is

\[
P_{[a,b]}(\lambda;T) = \frac{e^{-\lambda a}-e^{-\lambda b}}{1-e^{-\lambda T}}.
\]

The code evaluates this using `expm1` for numerical stability. For `λ = 0` (a stable constant-in-time source), it uses `(b-a)/T`.

The main and each named contaminant may have different half-lives. For a signal–signal pair with rates `λ_i, λ_j`, the pair time shape uses the rate sum `λ_i + λ_j`; signal–background uses the primary signal rate, because the sampled experimental background is treated as stationary. The implemented source-pair overlap factor is

\[
K_{ij} = \frac{T\int_0^T e^{-(\lambda_i+\lambda_j)t}\,dt}
{\left(\int_0^T e^{-\lambda_i t}\,dt\right)\left(\int_0^T e^{-\lambda_j t}\,dt\right)}.
\]

When either decay rate is zero, the current `TimeOverlapK()` implementation uses `K = 1`. This is an explicit software convention and should not be reinterpreted as a complete physical derivation. The overlap affects allocation of an **already configured** S+S fraction among source pairs; it does not independently set the integrated S+S fraction.

The energyTime X-axis projection (sum over time bins) is required to reproduce the physical `3300` distribution to rounding precision. In the ML transform, only the X **energy-bin** width is applied; do **not** divide by time-bin width. See [shared log](SharedLog.md).

## Explicit settings and defaults

```ini
[energy_binning]
model = mtas354

[energy_time]
enabled = true
time_range_mode = half_lives
half_lives = 5
# time_unit = auto
# time_bin_width = 0  # auto; see implementation
```

The example above illustrates a typical 92Y+92Sr configuration. Actual defaults when a field is omitted are defined in `MixtureConfig.h` and should be distinguished from values in specific reference campaigns. See [configuration options](../reference/Configurations.md).
